const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { GoogleGenAI } = require("@google/genai");

// System prompt for MCAS Histamine & SIGHI scoring
const SYSTEM_PROMPT = `
You are an expert clinical dietitian and immunologist specializing in Mast Cell Activation Syndrome (MCAS), Histamine Intolerance, and the SIGHI food compatibility scale.

Analyze the meal image provided and return a single, valid, raw JSON object (with NO markdown backticks, NO \`\`\`json wrapping) adhering strictly to this schema:
{
  "mealName": "Descriptive meal name",
  "histamineScore": 0, // Integer: 0 (safe/low), 1 (moderately compatible), 2 (high risk), 3 (severe/incompatible)
  "liberatorScore": 0, // Integer: 0 (none), 1 (mild liberator), 2 (moderate), 3 (potent liberator)
  "confidenceScore": 0.95, // Float: 0.0 to 1.0
  "detectedIngredients": [
    {
      "name": "Ingredient name",
      "sighiScore": 0, // 0 to 3
      "isLiberator": false,
      "isBlocker": false,
      "notes": "Histamine risk & clinical explanation"
    }
  ],
  "detectedTriggers": ["Trigger 1", "Trigger 2"],
  "clinicalNotes": "Actionable guidance regarding freshness, DAO support, or preparation."
}
`;

exports.analyzeMealCentral = onCall({ cors: true, maxInstances: 10 }, async (request) => {
  const { imageBase64 } = request.data;
  if (!imageBase64) {
    throw new HttpsError("invalid-argument", "Missing imageBase64 payload.");
  }

  try {
    const ai = new GoogleGenAI();
    const response = await ai.models.generateContent({
      model: "gemini-2.5-flash",
      contents: [
        {
          role: "user",
          parts: [
            { text: SYSTEM_PROMPT + "\n\nAnalyze this meal image for MCAS histamine risk. Return strict JSON." },
            {
              inlineData: {
                mimeType: "image/jpeg",
                data: imageBase64,
              },
            },
          ],
        },
      ],
    });

    let text = response.text || "";
    text = text.replace(/```json/g, "").replace(/```/g, "").trim();
    return JSON.parse(text);
  } catch (error) {
    console.error("Central AI Error:", error);
    throw new HttpsError("internal", error.message || "Failed to analyze meal.");
  }
});
