#!/usr/bin/env bash
set -e
git init -q
git config user.name "Test Author"
git config user.email "test@example.com"
mkdir -p src/api src/storage
cat > package.json <<'SRC'
{ "name": "resize-api", "version": "0.9.0", "dependencies": { "express": "^4.19.0", "sharp": "^0.33.0" } }
SRC
cat > README.md <<'SRC'
# resize-api

HTTP API that stores uploaded images and returns resized copies.
SRC
cat > src/api/resize.js <<'SRC'
const express = require('express');
const sharp = require('sharp');
const bucket = require('../storage/bucket');

const router = express.Router();

// Resizes inside the request: large uploads can take 20-40 s.
router.post('/resize', async (req, res) => {
  const { width, height } = req.query;
  const output = await sharp(req.body).resize(Number(width), Number(height)).toBuffer();
  const key = await bucket.put(output);
  res.json({ key });
});

module.exports = router;
SRC
cat > src/storage/bucket.js <<'SRC'
// Thin wrapper around the object storage client.
async function put(buffer) {
  return `images/${Date.now()}.jpg`;
}

module.exports = { put };
SRC
git add -A
git commit -qm "chore: initial commit"
