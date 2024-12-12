import os
import argparse
import json
import logging
import hashlib
from typing import List, Optional, Tuple
from urllib.parse import urlparse, parse_qs
import googleapiclient.discovery
from vaderSentiment.vaderSentiment import SentimentIntensityAnalyzer
from transformers import pipeline
from tqdm import tqdm
import numpy as np
import time
from datetime import datetime, timedelta


# Configuration
CONFIG_FILE = "config.json"
DEFAULT_CONFIG = {
    "cache_dir": "cache",
    "log_file": "sentiment_analyzer.log",
    "sentiment_model": "cardiffnlp/twitter-roberta-base-sentiment-latest",
    "cache_expiry_days": 7
}

def load_config():
    """Loads configuration from config.json or uses defaults."""
    if os.path.exists(CONFIG_FILE):
        with open(CONFIG_FILE, "r") as f:
            config = json.load(f)
        # Ensure all keys are present, using defaults if not
        for key, default_value in DEFAULT_CONFIG.items():
            if key not in config:
                config[key] = default_value
        return config
    else:
        return DEFAULT_CONFIG

config = load_config()

# Setup logging
logging.basicConfig(filename=config["log_file"], level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')

def get_video_id(url: str) -> Optional[str]:
    """Extracts the video ID from a YouTube URL. Returns None if the URL is invalid."""
    parsed_url = urlparse(url)
    if parsed_url.netloc == 'www.youtube.com':
        if parsed_url.path == '/watch':
            query_params = parse_qs(parsed_url.query)
            if 'v' in query_params:
                return query_params['v'][0]
    elif parsed_url.netloc == 'youtu.be':
        return parsed_url.path[1:]
    logging.error(f"Invalid YouTube URL: {url}")
    print("Invalid YouTube URL.")
    return None

def _load_cached_data(cache_file: str, expiry_days: int) -> Optional[dict]:
    """Loads data from cache if it's not expired."""
    if os.path.exists(cache_file):
        try:
            with open(cache_file, "r") as f:
                cache_data = json.load(f)
            
            if 'timestamp' in cache_
                timestamp = datetime.fromisoformat(cache_data['timestamp'])
                if datetime.now() - timestamp <= timedelta(days=expiry_days):
                    logging.info(f"Loading from cache: {cache_file}")
                    return cache_data
                else:
                    logging.info(f"Cache expired: {cache_file}")
                    return None
            else:
                logging.info(f"Cache file missing timestamp: {cache_file}")
                return None
        except (json.JSONDecodeError, KeyError) as e:
            logging.error(f"Error loading cache file {cache_file}: {e}")
            return None
    return None

def _save_cached_data(cache_file: str,  data):
    """Saves data to cache with a timestamp."""
    os.makedirs(os.path.dirname(cache_file), exist_ok=True)
    data['timestamp'] = datetime.now().isoformat()
    with open(cache_file, "w") as f:
        json.dump(data, f)
    logging.info(f"Saved to cache: {cache_file}")

def get_youtube_comments(youtube, video_id: str, force_refresh: bool = False) -> Optional[List[str]]:
    """Fetches comments from a YouTube video, using cache if available."""
    cache_file = os.path.join(config["cache_dir"], f"{video_id}_comments.json")
    
    if not force_refresh:
        cached_data = _load_cached_data(cache_file, config["cache_expiry_days"])
        if cached_data and 'comments' in cached_data:
            return cached_data['comments']

    comments = []
    try:
        results = youtube.commentThreads().list(
            part="snippet",
            videoId=video_id,
            textFormat="plainText"
        ).execute()
        
        print("Fetching comments...")
        comment_count = 0
        with tqdm(unit="comments") as pbar:
            while results:
                for item in results['items']:
                    comment = item['snippet']['topLevelComment']['snippet']['textDisplay']
                    comments.append(comment)
                    comment_count += 1
                    pbar.update(1)
                if 'nextPageToken' in results:
                    results = youtube.commentThreads().list(
                        part="snippet",
                        videoId=video_id,
                        textFormat="plainText",
                        pageToken=results['nextPageToken']
                    ).execute()
                else:
                    break
        print(f"Total comments fetched: {comment_count}")
        
        # Save to cache
        _save_cached_data(cache_file, {'comments': comments})
    except Exception as e:
        logging.error(f"An error occurred while fetching comments: {e}")
        print(f"An error occurred: {e}")
        return None
    return comments

def analyze_sentiment(comments: List[str], sentiment_model: str) -> Tuple[str, float, dict, list, list, List[Tuple[int, str, float, dict]]]:
    """Analyzes the sentiment of a list of comments using VADER and a transformer model."""
    cache_key = hashlib.md5(f"{str(comments)}-{sentiment_model}".encode()).hexdigest()
    cache_file = os.path.join(config["cache_dir"], f"{cache_key}_sentiment.json")
    
    cached_data = _load_cached_data(cache_file, config["cache_expiry_days"])
    if cached_data and 'sentiment' in cached_
        return (cached_data['sentiment'], cached_data['average_score'], 
                cached_data['sentiment_counts'], cached_data['positive_comments'], 
                cached_data['negative_comments'], cached_data['sentiment_over_time'])

    analyzer = SentimentIntensityAnalyzer()
    sentiment_pipeline = pipeline("sentiment-analysis", model=sentiment_model)
    
    vader_scores = [analyzer.polarity_scores(comment)['compound'] for comment in comments]
    if not vader_scores:
        return "neutral", 0.0, {"positive": 0, "negative": 0, "neutral": 0}, [], [], []
    average_score = sum(vader_scores) / len(vader_scores)

    if average_score >= 0.05:
        sentiment = "positive"
    elif average_score <= -0.05:
        sentiment = "negative"
    else:
        sentiment = "neutral"

    # Detailed sentiment breakdown
    sentiment_counts = {"positive": 0, "negative": 0, "neutral": 0}
    
    sentiment_results = []
    print("Analyzing sentiment...")
    with tqdm(total=len(comments), unit="comment") as pbar:
        for comment in comments:
            try:
                result = sentiment_pipeline(comment)[0]
                label = result['label']
                score = result['score']
                sentiment_results.append((comment, label, score))
                if label == "positive":
                    sentiment_counts["positive"] += 1
                elif label == "negative":
                    sentiment_counts["negative"] += 1
                else:
                    sentiment_counts["neutral"] += 1
            except Exception as e:
                logging.warning(f"Error during transformer sentiment analysis: {e}")
                sentiment_counts["neutral"] += 1
            pbar.update(1)
    
    # Identify most positive and negative comments
    positive_comments = sorted([item for item in sentiment_results if item[1] == "positive"], key=lambda x: x[2], reverse=True)[:5]
    negative_comments = sorted([item for item in sentiment_results if item[1] == "negative"], key=lambda x: x[2], reverse=True)[:5]
    
    # Sentiment over time
    sentiment_over_time = []
    batch_size = 100  # Adjust as needed
    for i in range(0, len(comments), batch_size):
        batch = comments[i:i + batch_size]
        batch_vader_scores = [analyzer.polarity_scores(comment)['compound'] for comment in batch]
        if batch_vader_scores:
            batch_average_score = sum(batch_vader_scores) / len(batch_vader_scores)
            batch_sentiment = "positive" if batch_average_score >= 0.05 else "negative" if batch_average_score <= -0.05 else "neutral"
            sentiment_over_time.append((i, batch_sentiment, batch_average_score, {"positive": sum(1 for item in sentiment_results[i:i + batch_size] if item[1] == "positive"),
                                                                                  "negative": sum(1 for item in sentiment_results[i:i + batch_size] if item[1] == "negative"),
                                                                                  "neutral": sum(1 for item in sentiment_results[i:i + batch_size] if item[1] == "neutral")}))
    
    # Save to cache
    cache_data = {
        'sentiment': sentiment,
        'average_score': average_score,
        'sentiment_counts': sentiment_counts,
        'positive_comments': positive_comments,
        'negative_comments': negative_comments,
        'sentiment_over_time': sentiment_over_time
    }
    _save_cached_data(cache_file, cache_data)
    
    return sentiment, average_score, sentiment_counts, positive_comments, negative_comments, sentiment_over_time

def main():
    """Main function to run the sentiment analysis."""
    parser = argparse.ArgumentParser(description="Analyze sentiment of YouTube video comments.")
    parser.add_argument("video_url", help="YouTube video URL")
    parser.add_argument("--force-refresh", action="store_true", help="Force refresh of cached data.")
    args = parser.parse_args()

    api_service_name = "youtube"
    api_version = "v3"
    api_key = os.environ.get("YOUTUBE_API_KEY") # Set your API key as an environment variable

    if not api_key:
        logging.error("YOUTUBE_API_KEY environment variable not set.")
        print("Please set the YOUTUBE_API_KEY environment variable.")
        return

    try:
        youtube = googleapiclient.discovery.build(api_service_name, api_version, developerKey=api_key)
    except Exception as e:
        logging.error(f"Error building YouTube API service: {e}")
        print(f"Error building YouTube API service: {e}")
        return

    video_id = get_video_id(args.video_url)

    if not video_id:
        return

    comments = get_youtube_comments(youtube, video_id, args.force_refresh)

    if comments is None:
        return

    if not comments:
        print("No comments found for this video.")
        return

    sentiment, average_score, sentiment_counts, positive_comments, negative_comments, sentiment_over_time = analyze_sentiment(comments, config["sentiment_model"])
    print(f"Overall sentiment of the video: {sentiment}")
    print(f"Average compound score: {average_score:.2f}")
    print("Sentiment breakdown:")
    for key, value in sentiment_counts.items():
        print(f"  {key}: {value}")
    
    print("\nMost positive comments:")
    for comment, label, score in positive_comments:
        print(f"  - {comment[:100]}... (score: {score:.2f})")
    
    print("\nMost negative comments:")
    for comment, label, score in negative_comments:
        print(f"  - {comment[:100]}... (score: {score:.2f})")
    
    print("\nSentiment over time:")
    for index, batch_sentiment, batch_average_score, batch_counts in sentiment_over_time:
        print(f"  - Comments {index}-{index + 99}: Sentiment: {batch_sentiment}, Average score: {batch_average_score:.2f}, Positive: {batch_counts['positive']}, Negative: {batch_counts['negative']}, Neutral: {batch_counts['neutral']}")

if __name__ == "__main__":
    main()
