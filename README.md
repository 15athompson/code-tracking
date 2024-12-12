# YouTube Sentiment Analyzer

This tool analyzes the sentiment of comments on a YouTube video. It fetches comments, performs sentiment analysis, and provides a detailed breakdown of the sentiment.

## Features

- **Command-line Interface:** Takes a YouTube video URL as a command-line argument.
- **Caching:** Caches comments and sentiment analysis results to avoid redundant API calls and computations.
- **Advanced Sentiment Analysis:** Uses a pre-trained transformer model from the `transformers` library for more accurate sentiment analysis, in addition to VADER.
- **Detailed Sentiment Breakdown:** Provides the number of positive, negative, and neutral comments.
- **Error Handling:** Includes error handling for the API key and other potential issues.
- **Logging:** Logs all activities and errors to a log file.
- **Progress Bar:** Uses `tqdm` to display a progress bar while fetching comments.
- **Configuration:** Loads configuration from a `config.json` file, or uses default values if the file does not exist.

## Prerequisites

- Python 3.6 or higher
- pip
- A Google Cloud Platform project with the YouTube Data API v3 enabled
- An API key for the YouTube Data API v3 (set as an environment variable `YOUTUBE_API_KEY`)

## Installation

1. Clone the repository:
   ```bash
   git clone <repository_url>
   cd <repository_directory>
   ```
2. Install the required packages:
   ```bash
   pip install -r requirements.txt
   ```
   (Note: You'll need to create a `requirements.txt` file with the following content:
   ```
   google-api-python-client
   vaderSentiment
   transformers
   torch
   tqdm
   ```
   )
3. Set the `YOUTUBE_API_KEY` environment variable:
   ```bash
   export YOUTUBE_API_KEY="YOUR_API_KEY"
   ```
   (Replace `YOUR_API_KEY` with your actual API key.)

## Usage

