import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns

# Load the synthetic data
data = pd.read_csv("synthetic_data.csv")

# --- Exploratory Data Analysis (EDA) ---

# Display basic information about the dataset
print("Dataset Info:")
print(data.info())

# Summary statistics for numerical variables
print("\nDescriptive Statistics:")
print(data.describe())

# Explore the distribution of education levels
print("\nEducation Level Distribution:")
print(data["Education Level"].value_counts())

# --- Visualizations ---

# Histogram of Age
plt.figure(figsize=(8, 6))
sns.histplot(data["Age"], bins=10, kde=True)
plt.title("Distribution of Age")
plt.xlabel("Age")
plt.ylabel("Count")
plt.show()

# Box plot of Income by Education Level
plt.figure(figsize=(10, 6))
sns.boxplot(x="Education Level", y="Income", data=data)
plt.title("Income Distribution by Education Level")
plt.xlabel("Education Level")
plt.ylabel("Income")
plt.show()

# Scatter plot of Purchase Frequency vs. Spending per Purchase
plt.figure(figsize=(8, 6))
sns.scatterplot(x="Purchase Frequency", y="Spending per Purchase", data=data)
plt.title("Purchase Frequency vs. Spending per Purchase")
plt.xlabel("Purchase Frequency")
plt.ylabel("Spending per Purchase")
plt.show()

# --- Identifying Patterns and Trends ---

# Convert 'Education Level' to numerical data using label encoding
from sklearn.preprocessing import LabelEncoder
le = LabelEncoder()
data['Education Level'] = le.fit_transform(data['Education Level'])

# Correlation matrix
correlation_matrix = data.corr()
print("\nCorrelation Matrix:")
print(correlation_matrix)

# Heatmap of the correlation matrix
plt.figure(figsize=(10, 8))
sns.heatmap(correlation_matrix, annot=True, cmap="coolwarm", fmt=".2f")
plt.title("Correlation Matrix Heatmap")
plt.show()

# Example: Analyze the relationship between Income and Purchase Frequency
# You can use regression analysis, groupby and aggregation, etc. to explore this further.

# --- Further Analysis ---

# You can perform more in-depth analysis based on your specific goals and questions.
# For example, you could:
# - Segment customers based on their characteristics (e.g., age, income, education)
# - Build predictive models to forecast purchase behavior
# - Conduct hypothesis testing to validate assumptions about the data

# This is just a starting point for your analysis. 
# Feel free to explore the data further and ask me any questions you have!
