const functions = require("firebase-functions");
const axios = require("axios");

exports.claudeProxy = functions.https.onRequest(async (req, res) => {
  try {
    const response = await axios.post(
      "https://api.anthropic.com/v1/messages",
      req.body,
      {
        headers: {
          "x-api-key": "sk-ant-xxx...",  // 🔑 Replace with your Claude API key
          "anthropic-version": "2023-06-01",
          "content-type": "application/json"
        }
      }
    );
    res.status(200).json(response.data);
  } catch (err) {
    console.error("Claude Proxy Error:", err.response?.data || err.message);
    res.status(500).send("Error connecting to Claude API");
  }
});
