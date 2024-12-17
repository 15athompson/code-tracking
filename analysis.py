import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns

# Load the synthetic data
plt.figure(figsize=(8, 6), dpi=100)
sns.histplot(data["Age"], bins=10, kde=True)
plt.title("Distribution of Age", fontsize=14)
plt.xlabel("Age", fontsize=12)
plt.ylabel("Count", fontsize=12)
plt.xticks(size=10)
plt.yticks(size=10)
plt.grid(alpha=0.3)
plt.show()


 # --- Predictive Modeling ---

from sklearn.linear_model import LinearRegression
from sklearn.model_selection import train_test_split
from sklearn.metrics import mean_squared_error, r2_score

 # Prepare the data
X = data[['Age', 'Income', 'Education Level']]
y = data['Spending per Purchase']

 # Split the data into training and testing sets
X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=42)

 # Create and train the linear regression model
model = LinearRegression()
model.fit(X_train, y_train)

 # Make predictions on the testing set
y_pred = model.predict(X_test)

 # Evaluate the model
mse = mean_squared_error(y_test, y_pred)
r2 = r2_score(y_test, y_pred)

print('\nPredictive Modeling - Linear Regression:')
print('Mean Squared Error:', mse)
print('R-squared:', r2)

 # --- Hypothesis Testing ---

from scipy.stats import ttest_ind

 # Test the hypothesis that there's a significant difference in purchase frequency between customers with different
 # education levels
high_school_purchase_frequency = data[data['Education Level'] == 'High School']['Purchase Frequency']
bachelors_purchase_frequency = data[data['Education Level'] == 'bachelors']['Purchase Frequency']
masters_purchase_frequency = data[data['Education Level'] == "Master's"]['Purchase Frequency']
phd_purchase_frequency = data[data['Education Level'] == 'PhD']['Purchase Frequency']

t_stat, p_value = ttest_ind(high_school_purchase_frequency, bachelors_purchase_frequency)
print('\nHypothesis Testing - Purchase Frequency (High School vs. Bachelors):')
print('T-statistic:', t_stat)
print('P-value:', p_value)

t_stat, p_value = ttest_ind(masters_purchase_frequency, phd_purchase_frequency)
print('\nHypothesis Testing - Purchase Frequency (Masters vs. PhD):')
print('T-statistic:', t_stat)
print('P-value:', p_value)


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


