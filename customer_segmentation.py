import pandas as pd
from sklearn.cluster import KMeans
from sklearn.preprocessing import StandardScaler

def load_data(file_path):
    """Loads customer data from a CSV file."""
    return pd.read_csv(file_path)

def preprocess_data(data):
    """Preprocesses the data for clustering."""
    # Select relevant features for segmentation
    features = ['purchase_frequency', 'average_order_value', 'customer_lifetime_value']
    X = data[features]

    # Scale the features
    scaler = StandardScaler()
    X_scaled = scaler.fit_transform(X)

    return X_scaled

def segment_customers(X_scaled, n_clusters=4):
    """Segments customers using KMeans clustering."""
    kmeans = KMeans(n_clusters=n_clusters, random_state=42)
    kmeans.fit(X_scaled)
    return kmeans.labels_

def analyze_segments(data, labels):
    """Analyzes the characteristics of each customer segment."""
    data['segment'] = labels
    for i in range(n_clusters):
        segment_data = data[data['segment'] == i]
        print(f"Segment {i}:")
        print(segment_data.describe())

if __name__ == "__main__":
    # Load customer data
    data = load_data('customer_data.csv')  # Replace with your data file

    # Preprocess data
    X_scaled = preprocess_data(data)

    # Segment customers
    labels = segment_customers(X_scaled)

    # Analyze segments
    analyze_segments(data, labels)
