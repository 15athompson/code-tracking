import numpy as np
import pandas as pd

import matplotlib.pyplot as plt

# Generate synthetic stock data using Geometric Brownian Motion
np.random.seed(42)
dates = pd.date_range(start="2023-01-01", periods=252)  # 252 trading days in a year
initial_price = 100
drift = 0.05  # Annual drift
volatility = 0.2  # Annual volatility
dt = 1 / 252  # Time step (daily)

prices = [initial_price]
for _ in range(len(dates) - 1):
    prices.append(
        prices[-1]
        * np.exp(
            (drift - 0.5 * volatility**2) * dt
            + volatility * np.random.randn() * np.sqrt(dt)
        )
    )

# Create a Pandas DataFrame
df = pd.DataFrame({"Date": dates, "Price": prices})

# Implement a simple moving average crossover strategy
short_window = 20
long_window = 50
df["Short_MA"] = df["Price"].rolling(window=short_window).mean()
df["Long_MA"] = df["Price"].rolling(window=long_window).mean()
df["Signal"] = 0.0
df["Signal"][short_window:] = np.where(
    df["Short_MA"][short_window:] > df["Long_MA"][short_window:], 1.0, 0.0
)
df["Position"] = df["Signal"].diff()

# Calculate returns
df["Returns"] = df["Price"].pct_change()
df["Strategy_Returns"] = df["Returns"] * df["Position"].shift(1)

# Calculate cumulative returns
df["Cumulative_Returns"] = (1 + df["Returns"]).cumprod() - 1
df["Cumulative_Strategy_Returns"] = (1 + df["Strategy_Returns"]).cumprod() - 1

# Calculate performance metrics
sharpe_ratio = df["Strategy_Returns"].mean() / df["Strategy_Returns"].std() * np.sqrt(252)
max_drawdown = (
    df["Cumulative_Strategy_Returns"].cummax() - df["Cumulative_Strategy_Returns"]
).max()

# Print performance metrics
print("Sharpe Ratio:", sharpe_ratio)
print("Maximum Drawdown:", max_drawdown)

# Visualize the results
plt.figure(figsize=(12, 6))
plt.plot(df["Date"], df["Price"], label="Price")
plt.plot(df["Date"], df["Short_MA"], label="Short MA")
plt.plot(df["Date"], df["Long_MA"], label="Long MA")
plt.plot(
    df["Date"][df["Position"] == 1.0],
    df["Price"][df["Position"] == 1.0],
    "^",
    markersize=10,
    color="g",
    label="Buy",
)
plt.plot(
    df["Date"][df["Position"] == -1.0],
    df["Price"][df["Position"] == -1.0],
    "v",
    markersize=10,
    color="r",
    label="Sell",
)
plt.title("Stock Price with Moving Average Crossover Strategy")
plt.xlabel("Date")
plt.ylabel("Price")
plt.legend()
plt.grid(True)
plt.show()
