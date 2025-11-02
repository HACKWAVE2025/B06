import 'dotenv/config';
import { GoogleGenAI } from '@google/genai';
import fs from 'node:fs';
import path from 'node:path';
import mime from 'mime';
import crypto from 'crypto';
import fetch from 'node-fetch';

// In serverless environments the in-memory map is ephemeral. It will help
// detect duplicates for warm instances but won't persist across cold starts.
const processedImages = new Map();

const ai = new GoogleGenAI({ apiKey: process.env.GEMINI_API_KEY });

const sendJson = (res, status, obj) => {
  res.writeHead(status, { 'Content-Type': 'application/json' });
  res.end(JSON.stringify(obj));
};

const parseBody = async (req) => {
  if (req.body) return req.body;
  return new Promise((resolve, reject) => {
    let data = '';
    req.on('data', (chunk) => (data += chunk));
    req.on('end', () => {
      try {
        resolve(data ? JSON.parse(data) : {});
      } catch (e) {
        reject(e);
      }
    });
    req.on('error', reject);
  });
};

export default async function handler(req, res) {
  // CORS preflight
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Headers', 'Origin, X-Requested-With, Content-Type, Accept');
  res.setHeader('Access-Control-Allow-Methods', 'GET,POST,OPTIONS');
  if (req.method === 'OPTIONS') {
    res.writeHead(204);
    res.end();
    return;
  }

  if (req.method !== 'POST') {
    return sendJson(res, 405, { error: 'Only POST allowed' });
  }

  let body;
  try {
    body = await parseBody(req);
  } catch (err) {
    return sendJson(res, 400, { error: 'Invalid JSON body' });
  }

  const { prompt, imagePath, imageData, imageUrl } = body;
  if (!prompt) return sendJson(res, 400, { error: 'prompt is required' });

  const parts = [{ text: prompt }];

  try {
    let imageContent, mimeType;

    if (imageUrl) {
      try {
        const response = await fetch(imageUrl);
        if (!response.ok) throw new Error(`Failed to fetch image: ${response.statusText}`);
        const arr = await response.arrayBuffer();
        const buffer = Buffer.from(arr);
        imageContent = buffer.toString('base64');
        mimeType = response.headers.get('content-type') || 'image/png';
      } catch (err) {
        return sendJson(res, 400, { error: `Failed to fetch image from URL: ${err.message}` });
      }
    } else if (imagePath) {
      // In serverless environments local filesystem access is restricted.
      // We'll still attempt to resolve relative paths but this commonly fails on Vercel.
      try {
        const normalized = imagePath.replace(/\\/g, '/');
        const resolvedPath = path.resolve(normalized);
        imageContent = fs.readFileSync(resolvedPath, { encoding: 'base64' });
        mimeType = mime.getType(resolvedPath) || 'image/png';
      } catch (err) {
        return sendJson(res, 400, { error: `Failed to read imagePath: ${err.message}` });
      }
    } else if (imageData) {
      imageContent = imageData;
      mimeType = 'image/png';
    }

    if (imageContent) {
      const hash = crypto.createHash('sha256').update(imageContent).digest('hex');
      if (processedImages.has(hash)) {
        const previousTime = processedImages.get(hash);
        return sendJson(res, 400, { error: 'Duplicate image detected', previousUpload: previousTime });
      }
      processedImages.set(hash, new Date().toISOString());
      parts.push({ inlineData: { mimeType, data: imageContent } });
    }
  } catch (err) {
    return sendJson(res, 400, { error: `Failed to read image: ${err.message}` });
  }

  const model = 'gemini-2.5-flash';

  try {
    const response = await ai.models.generateContent({ model, contents: [{ parts }] });
    const caption = response?.candidates?.[0]?.content?.parts?.[0]?.text || null;
    const usage = response?.usageMetadata || null;
    return sendJson(res, 200, { caption, usage, raw: response });
  } catch (err) {
    if (err?.sdkHttpResponse) {
      return sendJson(res, 500, { error: err.sdkHttpResponse });
    }
    return sendJson(res, 500, { error: String(err) });
  }
}
