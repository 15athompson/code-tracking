import numpy as np
import pandas as pd
import yfinance as yf

import matplotlib.pyplot as plt

import numpy as np
import pandas as pd
import yfinance as yf

import matplotlib.pyplot as plt


def backtest_strategy(ticker, start_date, end_date, short_window, long_window, stop_loss_pct):
    # Fetch historical stock data from Yahoo Finance
    data = yf.download(ticker, start=start_date, end=end_date)

    # Create a Pandas DataFrame with adjusted closing prices
    df = pd.DataFrame({"Price": data["Adj Close"]})

    # Implement a simple moving average crossover strategy with risk management
    df["Short_MA"] = df["Price"].rolling(window=short_window).mean()
    df["Long_MA"] = df["Price"].rolling(window=long_window).mean()
    df["Signal"] = 0.0
    df["Signal"][short_window:] = np.where(
        df["Short_MA"][short_window:] > df["Long_MA"][short_window:], 1.0, 0.0
    )
    df["Position"] = df["Signal"].diff()

    # Implement stop-loss orders
    for i in range(short_window + 1, len(df)):
        if df["Position"][i] == 1:  # Long position
            stop_loss_price = df["Price"][i] * (1 - stop_loss_pct)
            for j in range(i + 1, len(df)):
                if df["Price"][j] < stop_loss_price:
                    df["Position"][j] = -1  # Exit position
                    break
        elif df["Position"][i] == -1:  # Short position
            stop_loss_price = df["Price"][i] * (1 + stop_loss_pct)
            for j in range(i + 1, len(df)):
                if df["Price"][j] > stop_loss_price:
                    df["Position"][j] = 1  # Exit position
                    break

    # Incorporate transaction costs
    transaction_cost = 0.001  # 0.1% per trade

    # Calculate returns
    df["Returns"] = df["Price"].pct_change()
    df["Strategy_Returns"] = df["Returns"] * df["Position"].shift(1)
    df["Strategy_Returns"][df["Position"].diff() != 0] -= transaction_cost

    # Calculate cumulative returns
    df["Cumulative_Returns"] = (1 + df["Returns"]).cumprod() - 1
    df["Cumulative_Strategy_Returns"] = (1 + df["Strategy_Returns"]).cumprod() - 1

    # Calculate performance metrics
    sharpe_ratio = (
        df["Strategy_Returns"].mean() / df["Strategy_Returns"].std() * np.sqrt(252)
    )
    max_drawdown = (
        df["Cumulative_Strategy_Returns"].cummax() - df["Cumulative_Strategy_Returns"]
    ).max()

    return sharpe_ratio, max_drawdown, df


# Backtest on different datasets
tickers = ["AAPL", "MSFT", "GOOG", "AMZN"]
start_dates = ["2020-01-01", "2021-01-01", "2022-01-01"]
end_date = "2024-01-01"
short_window = 20
long_window = 50
stop_loss_pct = 0.05

results = {}
for ticker in tickers:
    for start_date in start_dates:
        sharpe_ratio, max_drawdown, df = backtest_strategy(
            ticker, start_date, end_date, short_window, long_window, stop_loss_pct
        )
        results[(ticker, start_date)] = {
            "Sharpe Ratio": sharpe_ratio,
            "Maximum Drawdown": max_drawdown,
        }

        # Visualize the results for each dataset (optional)
        plt.figure(figsize=(12, 6))
        plt.plot(df.index, df["Price"], label="Price")
        plt.plot(df.index, df["Short_MA"], label="Short MA")
        plt.plot(df.index, df["Long_MA"], label="Long MA")
        plt.plot(
            df.index[df["Position"] == 1.0],
            df["Price"][df["Position"] == 1.0],
            "^",
            markersize=10,
            color="g",
            label="Buy",
        )
        plt.plot(
            df.index[df["Position"] == -1.0],
            df["Price"][df["Position"] == -1.0],
            "v",
            markersize=10,
            color="r",
            label="Sell",
        )
        plt.title(
            f"Stock Price with Moving Average Crossover Strategy ({ticker}, {start_date}-{end_date})"
        )
        plt.xlabel("Date")
        plt.ylabel("Price")
        plt.legend()
        plt.grid(True)
        plt.show()

# Print the results
for (ticker, start_date), metrics in results.items():
    print(f"Results for {ticker} ({start_date}-{end_date}):")
    print(f"  Sharpe Ratio: {metrics['Sharpe Ratio']:.2f}")
    print(f"  Maximum Drawdown: {metrics['Maximum Drawdown']:.2f}")
