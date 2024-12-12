import os
import googleapiclient.discovery
from vaderSentiment.vaderSentiment import SentimentIntensityAnalyzer
from urllib.parse import urlparse, parse_qs
from typing import List, Optional

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
    print("Invalid YouTube URL.")
    return None

def get_youtube_comments(youtube, video_id: str) -> Optional[List[str]]:
    """Fetches comments from a YouTube video."""
    comments = []
    try:
        results = youtube.commentThreads().list(
            part="snippet",
            videoId=video_id,
            textFormat="plainText"
        ).execute()
        
        print("Fetching comments...")
        comment_count = 0
        while results:
            for item in results['items']:
                comment = item['snippet']['topLevelComment']['snippet']['textDisplay']
                comments.append(comment)
                comment_count += 1
                if comment_count % 10 == 0:
                    print(f"Fetched {comment_count} comments...")
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
    except Exception as e:
        print(f"An error occurred: {e}")
        return None
    return comments

def analyze_sentiment(comments: List[str]) -> tuple[str, float]:
    """Analyzes the sentiment of a list of comments and returns the sentiment category and average compound score."""
    analyzer = SentimentIntensityAnalyzer()
    compound_scores = [analyzer.polarity_scores(comment)['compound'] for comment in comments]
    if not compound_scores:
        return "neutral", 0.0
    average_score = sum(compound_scores) / len(compound_scores)

    if average_score >= 0.05:
        sentiment = "positive"
    elif average_score <= -0.05:
        sentiment = "negative"
    else:
        sentiment = "neutral"
    return sentiment, average_score

def main():
    """Main function to run the sentiment analysis."""
    api_service_name = "youtube"
    api_version = "v3"
    api_key = os.environ.get("YOUTUBE_API_KEY") # Set your API key as an environment variable

    if not api_key:
        print("Please set the YOUTUBE_API_KEY environment variable.")
        return

    youtube = googleapiclient.discovery.build(api_service_name, api_version, developerKey=api_key)

    video_url = input("Enter YouTube video URL: ")
    video_id = get_video_id(video_url)

    if not video_id:
        return

    comments = get_youtube_comments(youtube, video_id)

    if comments is None:
        return

    if not comments:
        print("No comments found for this video.")
        return

    sentiment, average_score = analyze_sentiment(comments)
    print(f"Overall sentiment of the video: {sentiment}")
    print(f"Average compound score: {average_score:.2f}")

if __name__ == "__main__":
    main()
