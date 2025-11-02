import 'dotenv/config';
import express from 'express';
import { GoogleGenAI } from '@google/genai';
import fs from 'node:fs';
import path from 'node:path';
import mime from 'mime';
import crypto from 'crypto';
import fetch from 'node-fetch';

// Store image hashes to detect duplicates
const processedImages = new Map();

const app = express();
const port = process.env.PORT || 3000;

// Simple CORS middleware to allow requests from local dev servers (adjust in production)
app.use((req, res, next) => {
  res.header('Access-Control-Allow-Origin', '*');
  res.header('Access-Control-Allow-Headers', 'Origin, X-Requested-With, Content-Type, Accept');
  if (req.method === 'OPTIONS') {
    res.header('Access-Control-Allow-Methods', 'GET,POST,OPTIONS');
    return res.sendStatus(204);
  }
  next();
});

app.use(express.json({ limit: '10mb' }));
app.use(express.static(path.resolve('public')));

const ai = new GoogleGenAI({ apiKey: process.env.GEMINI_API_KEY });

app.post('/api/gemini', async (req, res) => {
  const { prompt, imagePath, imageData, imageUrl } = req.body;

  if (!prompt) return res.status(400).json({ error: 'prompt is required' });

  // Build contents parts
  const parts = [{ text: prompt }];
  let resolvedPath;

  try {
    let imageContent, mimeType;
    
    if (imageUrl) {
      // Fetch image from URL
      try {
        const response = await fetch(imageUrl);
        if (!response.ok) {
          throw new Error(`Failed to fetch image: ${response.statusText}`);
        }
        const buffer = await response.buffer();
        imageContent = buffer.toString('base64');
        mimeType = response.headers.get('content-type') || 'image/png';
      } catch (err) {
        return res.status(400).json({ error: `Failed to fetch image from URL: ${err.message}` });
      }
    } else if (imagePath) {
      // normalize and resolve
      const normalized = imagePath.replace(/\\/g, '/');
      resolvedPath = path.resolve(normalized);
      imageContent = fs.readFileSync(resolvedPath, { encoding: 'base64' });
      mimeType = mime.getType(resolvedPath) || 'image/png';
    } else if (imageData) {
      // imageData should be a base64 string
      imageContent = imageData;
      mimeType = 'image/png';
    }

    if (imageContent) {
      // Generate hash of the image content
      const hash = crypto.createHash('sha256').update(imageContent).digest('hex');
      
      // Check if we've seen this image before
      if (processedImages.has(hash)) {
        const previousTime = processedImages.get(hash);
        return res.status(400).json({ 
          error: 'Duplicate image detected',
          previousUpload: previousTime
        });
      }

      // Store the hash with timestamp
      processedImages.set(hash, new Date().toISOString());
      
      // Add image to parts for processing
      parts.push({ inlineData: { mimeType, data: imageContent } });
    }
  } catch (err) {
    return res.status(400).json({ error: `Failed to read image file: ${err.message}` });
  }

  const model = 'gemini-2.5-flash';

  try {
    const response = await ai.models.generateContent({ model, contents: [{ parts }] });

    const caption = response?.candidates?.[0]?.content?.parts?.[0]?.text || null;
    const usage = response?.usageMetadata || null;

    return res.json({ caption, usage, raw: response });
    console.log(response);
  } catch (err) {
    // If SDK provides structured http error
    if (err?.sdkHttpResponse) {
      console.error('Gemini error:', err.sdkHttpResponse);
      return res.status(500).json({ error: err.sdkHttpResponse });
    }
    console.error('Error calling Gemini:', err);
    return res.status(500).json({ error: String(err) });
  }
});

app.listen(port, () => {
  console.log(`Server running on http://localhost:${port}`);
});

export default app;
