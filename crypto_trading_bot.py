import ccxt
import time
import pandas as pd
import numpy as np
from datetime import datetime
import talib  # Add this for technical indicators
import logging

# --- Configuration ---

# Exchange API keys
exchange_id = 'binance'  # Replace with your exchange
api_key = 'YOUR_API_KEY'
secret_key = 'YOUR_SECRET_KEY'

# Trading pair
symbol = 'BTC/USDT'

# Trading parameters
timeframe = '1m'  # Timeframe for data
balance_percentage = 0.05  # Percentage of balance to use per trade
stop_loss_percentage = 0.01  # Stop loss percentage
take_profit_percentage = 0.02  # Take profit percentage

# Risk Management Parameters
max_open_trades = 3  # Maximum number of simultaneous open trades
risk_reward_ratio = 1.5  # Target risk-reward ratio for trades

# Backtesting Parameters (if applicable)
backtest_start_date = '2023-01-01 00:00:00'  # Start date for backtesting
backtest_end_date = '2023-12-31 23:59:59'  # End date for backtesting

# --- Logging ---
logging.basicConfig(filename='trading_bot.log', level=logging.INFO, 
                    format='%(asctime)s - %(levelname)s - %(message)s')

# --- Initialize Exchange ---

exchange = ccxt.binance({
    'apiKey': api_key,
    'secret': secret_key,
    'enableRateLimit': True,  # Enable rate limiting to avoid API request issues
})

# --- Data Loading and Preprocessing ---

def get_historical_data(symbol, timeframe, since=None, limit=1000):
    """Fetches historical data from the exchange."""
    try:
        ohlcv = exchange.fetch_ohlcv(symbol, timeframe=timeframe, since=since, limit=limit)
        df = pd.DataFrame(ohlcv, columns=['timestamp', 'open', 'high', 'low', 'close', 'volume'])
        df['timestamp'] = pd.to_datetime(df['timestamp'], unit='ms')
        df.set_index('timestamp', inplace=True)
        return df
    except ccxt.ExchangeError as e:
        logging.error(f"Error fetching historical  {e}")
        return None

# --- Trading Logic ---

def calculate_indicators(df):
    """Calculates technical indicators."""
    # Moving Averages
    df['SMA_20'] = talib.SMA(df['close'], timeperiod=20)
    df['SMA_50'] = talib.SMA(df['close'], timeperiod=50)

    # Relative Strength Index (RSI)
    df['RSI'] = talib.RSI(df['close'], timeperiod=14)

    # MACD
    df['MACD'], df['MACD_Signal'], df['MACD_Hist'] = talib.MACD(df['close'], fastperiod=12, slowperiod=26, signalperiod=9)

    # Bollinger Bands
    df['upper_band'], df['middle_band'], df['lower_band'] = talib.BBANDS(df['close'], timeperiod=20, nbdevup=2, nbdevdn=2, matype=0)

    # Average True Range (ATR) - for volatility-based stop-loss
    df['ATR'] = talib.ATR(df['high'], df['low'], df['close'], timeperiod=14)

    return df

def generate_trading_signals(df):
    """Generates buy and sell signals based on indicators."""
    df['signal'] = 0

    # Buy Signal:
    # - Price crosses above SMA 20 and SMA 50
    # - RSI is below 30 (oversold)
    # - MACD histogram is positive and increasing
    df.loc[(df['close'] > df['SMA_20']) & (df['close'] > df['SMA_50']) & (df['RSI'] < 30) & (df['MACD_Hist'] > 0) & (df['MACD_Hist'] > df['MACD_Hist'].shift(1)), 'signal'] = 1

    # Sell Signal:
    # - Price crosses below SMA 20 and SMA 50
    # - RSI is above 70 (overbought)
    # - MACD histogram is negative and decreasing
    df.loc[(df['close'] < df['SMA_20']) & (df['close'] < df['SMA_50']) & (df['RSI'] > 70) & (df['MACD_Hist'] < 0) & (df['MACD_Hist'] < df['MACD_Hist'].shift(1)), 'signal'] = -1

    return df

def execute_trade(symbol, side, amount, stop_loss_price=None, take_profit_price=None):
    """Executes a buy or sell order with optional stop-loss and take-profit."""
    try:
        order_type = 'market'  # You can change this to 'limit' if needed

        if stop_loss_price and take_profit_price:
            order = exchange.create_order(symbol, order_type, side, amount, params={
                'stopLoss': stop_loss_price,
                'takeProfit': take_profit_price,
            })
        else:
            order = exchange.create_order(symbol, order_type, side, amount)

        logging.info(f"Order placed: {order}")
    except ccxt.ExchangeError as e:
        logging.error(f"Error placing order: {e}")

# --- Risk Management ---

def get_position_size(balance, entry_price, stop_loss_price, risk_percentage):
    """Calculates the position size based on risk management parameters."""
    risk_amount = balance * risk_percentage
    stop_loss_distance = abs(entry_price - stop_loss_price)
    position_size = risk_amount / stop_loss_distance
    return position_size

def get_open_trades(exchange, symbol):
    """Gets the list of open trades for the given symbol."""
    open_trades = []
    try:
        for trade in exchange.fetch_open_orders(symbol):
            if trade['status'] == 'open':
                open_trades.append(trade)
    except ccxt.ExchangeError as e:
        logging.error(f"Error fetching open trades: {e}")
    return open_trades

# --- Backtesting (Optional) ---

def backtest(df):
    """Performs backtesting on historical data."""
    initial_balance = 1000  # Starting balance for backtesting
    balance = initial_balance
    trades = []

    for i in range(len(df)):
        if df['signal'][i] == 1:
            # Buy signal
            entry_price = df['close'][i]
            stop_loss_price = entry_price * (1 - stop_loss_percentage)
            take_profit_price = entry_price * (1 + take_profit_percentage)
            amount = get_position_size(balance, entry_price, stop_loss_price, balance_percentage)

            # Simulate trade execution
            if balance >= amount * entry_price:
                balance -= amount * entry_price
                trades.append({'timestamp': df.index[i], 'side': 'buy', 'price': entry_price, 'amount': amount, 'stop_loss': stop_loss_price, 'take_profit': take_profit_price})

        elif df['signal'][i] == -1 and len(trades) > 0:
            # Sell signal (close the oldest open trade)
            open_trade = trades.pop(0)
            exit_price = df['close'][i]

            # Simulate trade exit
            if exit_price >= open_trade['take_profit']:
                balance += open_trade['amount'] * open_trade['take_profit']
            elif exit_price <= open_trade['stop_loss']:
                balance += open_trade['amount'] * open_trade['stop_loss']
            else:
                balance += open_trade['amount'] * exit_price

    final_balance = balance
    profit = final_balance - initial_balance
    profit_percentage = (profit / initial_balance) * 100

    print(f"Backtesting Results:")
    print(f"Initial Balance: {initial_balance}")
    print(f"Final Balance: {final_balance}")
    print(f"Profit: {profit}")
    print(f"Profit Percentage: {profit_percentage:.2f}%")

    return trades

# --- Main Loop ---

def main():
    """Main trading loop."""

    if backtest_start_date and backtest_end_date:
        # Backtesting mode
        since = int(pd.Timestamp(backtest_start_date).timestamp() * 1000)
        df = get_historical_data(symbol, timeframe, since=since)
        if df is not None:
            df = calculate_indicators(df)
            df = generate_trading_signals(df)
            backtest(df)
    else:
        # Live trading mode
        while True:
            # Fetch latest data
            df = get_historical_data(symbol, timeframe)
            if df is not None:
                # Calculate indicators
                df = calculate_indicators(df)

                # Generate trading signals
                df = generate_trading_signals(df)

                # Check for signals and risk management
                if df['signal'].iloc[-1] == 1 and len(get_open_trades(exchange, symbol)) < max_open_trades:
                    # Buy signal
                    balance = exchange.fetch_balance()['USDT']['free']
                    entry_price = df['close'].iloc[-1]
                    stop_loss_price = entry_price * (1 - stop_loss_percentage)
                    take_profit_price = entry_price * (1 + take_profit_percentage * risk_reward_ratio)
                    amount = get_position_size(balance, entry_price, stop_loss_price, balance_percentage)
                    execute_trade(symbol, 'buy', amount, stop_loss_price, take_profit_price)

                elif df['signal'].iloc[-1] == -1:
                    # Sell signal
                    try:
                        position = exchange.fetch_positions()[0]  # Assuming only one open position
                        amount = position['amount']
                        execute_trade(symbol, 'sell', amount)
                    except IndexError:
                        logging.warning("Sell signal generated, but no open position found.")

                # Sleep for a specified interval
                time.sleep(60)

if __name__ == '__main__':
    main()