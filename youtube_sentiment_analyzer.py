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


# Configuration
CONFIG_FILE = "config.json"
DEFAULT_CONFIG = {
    "cache_dir": "cache",
    "log_file": "sentiment_analyzer.log"
}

def load_config():
    """Loads configuration from config.json or uses defaults."""
    if os.path.exists(CONFIG_FILE):
        with open(CONFIG_FILE, "r") as f:
            config = json.load(f)
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

def get_youtube_comments(youtube, video_id: str) -> Optional[List[str]]:
    """Fetches comments from a YouTube video."""
    cache_file = os.path.join(config["cache_dir"], f"{video_id}_comments.json")
    if os.path.exists(cache_file):
        logging.info(f"Loading comments from cache: {cache_file}")
        with open(cache_file, "r") as f:
            return json.load(f)

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
        os.makedirs(config["cache_dir"], exist_ok=True)
        with open(cache_file, "w") as f:
            json.dump(comments, f)
        logging.info(f"Comments saved to cache: {cache_file}")
    except Exception as e:
        logging.error(f"An error occurred while fetching comments: {e}")
        print(f"An error occurred: {e}")
        return None
    return comments

def analyze_sentiment(comments: List[str]) -> Tuple[str, float, dict, list, list]:
    """Analyzes the sentiment of a list of comments using VADER and a transformer model."""
    cache_file = os.path.join(config["cache_dir"], f"{hashlib.md5(str(comments).encode()).hexdigest()}_sentiment.json")
    if os.path.exists(cache_file):
        logging.info(f"Loading sentiment analysis from cache: {cache_file}")
        with open(cache_file, "r") as f:
            return tuple(json.load(f))

    analyzer = SentimentIntensityAnalyzer()
    sentiment_pipeline = pipeline("sentiment-analysis", model="cardiffnlp/twitter-roberta-base-sentiment-latest")
    
    vader_scores = [analyzer.polarity_scores(comment)['compound'] for comment in comments]
    if not vader_scores:
        return "neutral", 0.0, {"positive": 0, "negative": 0, "neutral": 0}, [], []
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
    
    # Save to cache
    os.makedirs(config["cache_dir"], exist_ok=True)
    with open(cache_file, "w") as f:
        json.dump((sentiment, average_score, sentiment_counts, positive_comments, negative_comments), f)
    logging.info(f"Sentiment analysis saved to cache: {cache_file}")
    return sentiment, average_score, sentiment_counts, positive_comments, negative_comments

def main():
    """Main function to run the sentiment analysis."""
    parser = argparse.ArgumentParser(description="Analyze sentiment of YouTube video comments.")
    parser.add_argument("video_url", help="YouTube video URL")
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

    comments = get_youtube_comments(youtube, video_id)

    if comments is None:
        return

    if not comments:
        print("No comments found for this video.")
        return

    sentiment, average_score, sentiment_counts, positive_comments, negative_comments = analyze_sentiment(comments)
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

if __name__ == "__main__":
    main()
