import os
import googleapiclient.discovery
from vaderSentiment.vaderSentiment import SentimentIntensityAnalyzer
from urllib.parse import urlparse, parse_qs

def get_video_id(url):
    """Extracts the video ID from a YouTube URL."""
    parsed_url = urlparse(url)
    if parsed_url.netloc == 'www.youtube.com':
        if parsed_url.path == '/watch':
            query_params = parse_qs(parsed_url.query)
            if 'v' in query_params:
                return query_params['v'][0]
    elif parsed_url.netloc == 'youtu.be':
        return parsed_url.path[1:]
    return None

def get_youtube_comments(youtube, video_id):
    """Fetches comments from a YouTube video."""
    comments = []
    try:
        results = youtube.commentThreads().list(
            part="snippet",
            videoId=video_id,
            textFormat="plainText"
        ).execute()

        while results:
            for item in results['items']:
                comment = item['snippet']['topLevelComment']['snippet']['textDisplay']
                comments.append(comment)
            if 'nextPageToken' in results:
                results = youtube.commentThreads().list(
                    part="snippet",
                    videoId=video_id,
                    textFormat="plainText",
                    pageToken=results['nextPageToken']
                ).execute()
            else:
                break
    except Exception as e:
        print(f"An error occurred: {e}")
        return None
    return comments

def analyze_sentiment(comments):
    """Analyzes the sentiment of a list of comments."""
    analyzer = SentimentIntensityAnalyzer()
    compound_scores = [analyzer.polarity_scores(comment)['compound'] for comment in comments]
    if not compound_scores:
        return "neutral"
    average_score = sum(compound_scores) / len(compound_scores)

    if average_score >= 0.05:
        return "positive"
    elif average_score <= -0.05:
        return "negative"
    else:
        return "neutral"

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
        print("Invalid YouTube URL.")
        return

    comments = get_youtube_comments(youtube, video_id)

    if comments is None:
        return

    if not comments:
        print("No comments found for this video.")
        return

    sentiment = analyze_sentiment(comments)
    print(f"Overall sentiment of the video: {sentiment}")

if __name__ == "__main__":
    main()
