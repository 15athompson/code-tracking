import numpy as np
import pandas as pd

# Generate synthetic stock data
np.random.seed(42)
dates = pd.date_range(start="2023-01-01", periods=100)
prices = 100 + np.cumsum(np.random.randn(100))

# Create a Pandas DataFrame
df = pd.DataFrame({"Date": dates, "Price": prices})

# Perform basic analysis
mean_price = df["Price"].mean()
std_price = df["Price"].std()

# Print the analysis results
print("Mean Price:", mean_price)
print("Standard Deviation of Price:", std_price)
