import ccxt
import time
import pandas as pd
import numpy as np
from datetime import datetime

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

# --- Initialize Exchange ---

exchange = ccxt.binance({
    'apiKey': api_key,
    'secret': secret_key,
})

# --- Data Loading and Preprocessing ---

def get_historical_data(symbol, timeframe, limit=1000):
    """Fetches historical data from the exchange."""
    ohlcv = exchange.fetch_ohlcv(symbol, timeframe=timeframe, limit=limit)
    df = pd.DataFrame(ohlcv, columns=['timestamp', 'open', 'high', 'low', 'close', 'volume'])
    df['timestamp'] = pd.to_datetime(df['timestamp'], unit='ms')
    df.set_index('timestamp', inplace=True)
    return df

# --- Trading Logic ---

def calculate_indicators(df):
    """Calculates technical indicators."""
    df['SMA_20'] = df['close'].rolling(window=20).mean()
    df['RSI'] = calculate_rsi(df['close'], period=14)
    return df

def calculate_rsi(prices, period=14):
    """Calculates the Relative Strength Index (RSI)."""
    delta = prices.diff()
    gain = delta.where(delta > 0, 0)
    loss = -delta.where(delta < 0, 0)
    avg_gain = gain.rolling(window=period).mean()
    avg_loss = loss.rolling(window=period).mean()
    rs = avg_gain / avg_loss
    rsi = 100 - (100 / (1 + rs))
    return rsi

def generate_trading_signals(df):
    """Generates buy and sell signals based on indicators."""
    df['signal'] = 0
    df.loc[(df['SMA_20'] < df['close']) & (df['RSI'] < 30), 'signal'] = 1  # Buy signal
    df.loc[(df['SMA_20'] > df['close']) & (df['RSI'] > 70), 'signal'] = -1  # Sell signal
    return df

def execute_trade(symbol, side, amount):
    """Executes a buy or sell order."""
    try:
        order = exchange.create_market_order(symbol, side, amount)
        print(f"Order placed: {order}")
    except Exception as e:
        print(f"Error placing order: {e}")

# --- Main Loop ---

def main():
    """Main trading loop."""
    while True:
        # Fetch latest data
        df = get_historical_data(symbol, timeframe)

        # Calculate indicators
        df = calculate_indicators(df)

        # Generate trading signals
        df = generate_trading_signals(df)

        # Check for signals
        if df['signal'].iloc[-1] == 1:
            # Buy signal
            balance = exchange.fetch_balance()['USDT']['free']
            amount = balance * balance_percentage
            execute_trade(symbol, 'buy', amount)

        elif df['signal'].iloc[-1] == -1:
            # Sell signal
            position = exchange.fetch_positions()[0]
            amount = position['amount']
            execute_trade(symbol, 'sell', amount)

        # Sleep for a specified interval
        time.sleep(60)

if __name__ == '__main__':
    main()
