// **WARNING:** Hardcoding API keys is extremely insecure.  Do NOT do this in production.
const API_KEY = "YOUR_API_KEY_HERE"; // Replace with your actual API key

async function fetchVoices() {
  try {
    const response = await fetch("https://api.elevenlabs.io/v1/voices", {
      headers: {
        "xi-api-key": API_KEY,
      },
    });
    if (!response.ok) {
      throw new Error(`HTTP error! status: ${response.status}`);
    }
    const data = await response.json();
    console.log("Voices:", data.voices);
    return data.voices;
  } catch (error) {
    console.error("Error fetching voices:", error);
    return null;
  }
}


async function textToSpeech(voiceId, text) {
  try {
    const response = await fetch(`https://api.elevenlabs.io/v1/text-to-speech/${voiceId}/stream`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'xi-api-key': API_KEY
      },
      body: JSON.stringify({
        text: text,
        model_id: "eleven_multilingual_v2", //Example model ID
        voice_settings: {
          stability: 0.5,
          similarity_boost: 0.8
        }
      })
    });

    if (!response.ok) {
      throw new Error(`HTTP error! status: ${response.status}`);
    }

    const reader = response.body.getReader();
    let audioBlob = new Blob([]);
    while (true) {
      const { done, value } = await reader.read();
      if (done) break;
      const newBlob = new Blob([audioBlob, value], { type: 'audio/mpeg' });
      audioBlob = newBlob;
    }
    const audioUrl = URL.createObjectURL(audioBlob);
    console.log("Audio URL:", audioUrl);
    //Play audio using audioUrl (requires additional code and potentially a library like Howler.js)
    return audioUrl;

  } catch (error) {
    console.error("Error generating speech:", error);
    return null;
  }
}


// Example usage:
fetchVoices();
textToSpeech("YOUR_VOICE_ID", "Hello, world!"); //Replace with a valid voice ID


