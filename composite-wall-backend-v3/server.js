require('dotenv').config();
const express = require('express');
const cors = require('cors');
const axios = require('axios');
const { body, validationResult } = require('express-validator');

const app = express();
const PORT = process.env.PORT || 3000;

// ─────────────────────────────────────────────────────────────────
// Google Gemini — 100% FREE API
// Get your free key: https://aistudio.google.com/app/apikey
// Free tier: 15 requests/min, 1 million tokens/day
// ─────────────────────────────────────────────────────────────────
const GEMINI_API_KEY = process.env.GEMINI_API_KEY || '';
const GEMINI_MODEL   = 'gemini-2.0-flash';
const GEMINI_URL     = () =>
  `https://generativelanguage.googleapis.com/v1beta/models/${GEMINI_MODEL}:generateContent?key=${GEMINI_API_KEY}`;

app.use(cors());
app.use(express.json());

// ─── Material Library ─────────────────────────────────────────────
let materialLibrary = [
  { id: 'mat4', name: 'Material 4', label: 'Cementitious Outer Layer', k: 0.7,   density: 1200, specificHeat: 880,  thickness: 0.5, color: '4289001466' },
  { id: 'mat1', name: 'Material 1', label: 'Mineral Wool Insulation',  k: 0.1,   density: 160,  specificHeat: 840,  thickness: 25,  color: '4294944565' },
  { id: 'mat2', name: 'Material 2', label: 'Aerogel Blanket',          k: 0.037, density: 170,  specificHeat: 1000, thickness: 6,   color: '4278225151' },
  { id: 'mat3', name: 'Material 3', label: 'Cementitious Inner Layer', k: 0.7,   density: 1200, specificHeat: 880,  thickness: 0.5, color: '4294956800' },
];
let defaultBc = { T_hot: 200, T_ambient: 50, h_conv: 4, area: 1 };

// ─── Thermal Engine ───────────────────────────────────────────────
function computeWall(materials, bc) {
  const { T_hot, T_ambient, h_conv, area } = bc;
  if (!materials?.length) throw new Error('At least one layer required');
  const layers = materials.map(mat => {
    const t_m = mat.thickness / 1000;
    return { ...mat, t_m, R: t_m / (mat.k * area) };
  });
  const R_conv  = 1 / (h_conv * area);
  const R_cond  = layers.reduce((s, l) => s + l.R, 0);
  const R_total = R_cond + R_conv;
  const q       = (T_hot - T_ambient) / R_total;
  const profile = [];
  let T_cur = T_hot, cumMm = 0;
  profile.push({ position: 0, temperature: T_cur, label: 'Hot Surface (Ts)' });
  const layerAnalysis = layers.map(l => {
    const T_in = T_cur;
    T_cur -= q * l.R;
    cumMm += l.thickness;
    profile.push({ position: cumMm, temperature: +T_cur.toFixed(4), label: `After ${l.name}` });
    return {
      name: l.name, label: l.label || '',
      thickness_mm: l.thickness, k_W_mK: l.k, density_kg_m3: l.density,
      R_conduction: +l.R.toFixed(6),
      T_in: +T_in.toFixed(4), T_out: +T_cur.toFixed(4),
      dT: +(T_in - T_cur).toFixed(4), heatFlux_W: +q.toFixed(4),
      color: l.color || '4288585374',
    };
  });
  profile.push({ position: cumMm, temperature: T_ambient, label: 'Ambient (T\u221e)' });
  const dominant = layers.reduce((a, b) => a.R > b.R ? a : b);
  return {
    success: true,
    results: {
      heatFlux_W: +q.toFixed(4), heatFlux_W_per_m2: +(q / area).toFixed(4),
      R_total: +R_total.toFixed(6), R_conduction_total: +R_cond.toFixed(6),
      R_convection: +R_conv.toFixed(6), deltaT_total: T_hot - T_ambient,
      totalThickness_mm: layers.reduce((s, l) => s + l.thickness, 0),
      biotNumber: +((h_conv * dominant.t_m) / dominant.k).toFixed(4),
    },
    temperatureProfile: profile, layerAnalysis,
    computedAt: new Date().toISOString(),
  };
}

// ─── Google Gemini Helpers ────────────────────────────────────────
const SYSTEM_CONTEXT = `You are a thermal engineering expert. Be concise, technical, and practical. Use metric units. Max 150 words. No markdown.`;

async function callGemini(userMessage, maxTokens = 256) {
  if (!GEMINI_API_KEY) throw new Error('GEMINI_API_KEY not configured. Get free key at https://aistudio.google.com/app/apikey');
  const res = await axios.post(GEMINI_URL(), {
    contents: [{ role: 'user', parts: [{ text: SYSTEM_CONTEXT + '\n\n' + userMessage }] }],
    generationConfig: { maxOutputTokens: maxTokens, temperature: 0.3, topP: 0.9 },
    safetySettings: [
      { category: 'HARM_CATEGORY_HARASSMENT',        threshold: 'BLOCK_NONE' },
      { category: 'HARM_CATEGORY_HATE_SPEECH',       threshold: 'BLOCK_NONE' },
      { category: 'HARM_CATEGORY_SEXUALLY_EXPLICIT', threshold: 'BLOCK_NONE' },
      { category: 'HARM_CATEGORY_DANGEROUS_CONTENT', threshold: 'BLOCK_NONE' },
    ],
  }, { headers: { 'Content-Type': 'application/json' }, timeout: 20000 });
  const text = res.data?.candidates?.[0]?.content?.parts?.[0]?.text;
  if (!text) throw new Error('Empty Gemini response');
  return text.trim();
}

async function callGeminiChat(history, newMessage, maxTokens = 256) {
  if (!GEMINI_API_KEY) throw new Error('GEMINI_API_KEY not configured');
  const contents = [
    { role: 'user',  parts: [{ text: SYSTEM_CONTEXT }] },
    { role: 'model', parts: [{ text: 'Understood. Ready to help with thermal engineering questions.' }] },
    ...history.map(m => ({ role: m.isUser ? 'user' : 'model', parts: [{ text: m.text }] })),
    { role: 'user', parts: [{ text: newMessage }] },
  ];
  const res = await axios.post(GEMINI_URL(), {
    contents,
    generationConfig: { maxOutputTokens: maxTokens, temperature: 0.3 },
  }, { headers: { 'Content-Type': 'application/json' }, timeout: 20000 });
  const text = res.data?.candidates?.[0]?.content?.parts?.[0]?.text;
  if (!text) throw new Error('Empty Gemini response');
  return text.trim();
}

// ─── Health ───────────────────────────────────────────────────────
app.get('/', (_, res) => res.json({
  service: 'Composite Wall CFD API v3', organization: 'Pentas Insulations Pvt Ltd', version: '3.0.1',
  ai: { provider: 'Google Gemini (FREE)', model: GEMINI_MODEL, enabled: Boolean(GEMINI_API_KEY) },
  freeKeyUrl: 'https://aistudio.google.com/app/apikey',
}));

// Reset materials to defaults
app.post('/api/reset', (_, res) => {
  materialLibrary = [
    { id: 'mat4', name: 'Material 4', label: 'Cementitious Outer Layer', k: 0.7,   density: 1200, specificHeat: 880,  thickness: 0.5, color: '4289001466' },
    { id: 'mat1', name: 'Material 1', label: 'Mineral Wool Insulation',  k: 0.1,   density: 160,  specificHeat: 840,  thickness: 25,  color: '4294944565' },
    { id: 'mat2', name: 'Material 2', label: 'Aerogel Blanket',          k: 0.037, density: 170,  specificHeat: 1000, thickness: 6,   color: '4278225151' },
    { id: 'mat3', name: 'Material 3', label: 'Cementitious Inner Layer', k: 0.7,   density: 1200, specificHeat: 880,  thickness: 0.5, color: '4294956800' },
  ];
  res.json({ success: true, message: 'Materials reset to defaults', materials: materialLibrary });
});

// ─── Materials ────────────────────────────────────────────────────
app.get('/api/materials', (_, res) => res.json({ success: true, materials: materialLibrary }));
app.post('/api/materials',
  [body('name').notEmpty(), body('k').isFloat({ min: 0.001 }), body('thickness').isFloat({ min: 0.01 })],
  (req, res) => {
    const errs = validationResult(req);
    if (!errs.isEmpty()) return res.status(400).json({ success: false, errors: errs.array() });
    const mat = { id: 'mat_' + Date.now(), ...req.body };
    materialLibrary.push(mat);
    res.status(201).json({ success: true, material: mat });
  });
app.put('/api/materials/:id', (req, res) => {
  const idx = materialLibrary.findIndex(m => m.id === req.params.id);
  if (idx < 0) return res.status(404).json({ success: false, error: 'Not found' });
  materialLibrary[idx] = { ...materialLibrary[idx], ...req.body, id: req.params.id };
  res.json({ success: true, material: materialLibrary[idx] });
});
app.delete('/api/materials/:id', (req, res) => {
  const idx = materialLibrary.findIndex(m => m.id === req.params.id);
  if (idx < 0) return res.status(404).json({ success: false, error: 'Not found' });
  res.json({ success: true, removed: materialLibrary.splice(idx, 1)[0] });
});

// ─── Boundary Conditions ─────────────────────────────────────────
app.get('/api/boundary-conditions', (_, res) => res.json({ success: true, boundaryConditions: defaultBc }));
app.put('/api/boundary-conditions', (req, res) => {
  defaultBc = { ...defaultBc, ...req.body };
  res.json({ success: true, boundaryConditions: defaultBc });
});

// ─── Calculate ───────────────────────────────────────────────────
app.post('/api/calculate', (req, res) => {
  try { res.json(computeWall(materialLibrary, { ...defaultBc, ...req.body })); }
  catch (e) { res.status(400).json({ success: false, error: e.message }); }
});
app.post('/api/calculate/custom',
  [body('materials').isArray({ min: 1 }), body('boundaryConditions.T_hot').isFloat()],
  (req, res) => {
    const errs = validationResult(req);
    if (!errs.isEmpty()) return res.status(400).json({ success: false, errors: errs.array() });
    try { res.json(computeWall(req.body.materials, req.body.boundaryConditions)); }
    catch (e) { res.status(400).json({ success: false, error: e.message }); }
  });

// ─── AI Routes (Google Gemini FREE) ──────────────────────────────

// GET /api/ai/status
app.get('/api/ai/status', async (req, res) => {
  if (!GEMINI_API_KEY) {
    return res.json({
      available: false, provider: 'Google Gemini (FREE)',
      reason: 'GEMINI_API_KEY not set',
      fix: 'Get free key at https://aistudio.google.com/app/apikey',
    });
  }
  try {
    await callGemini('Say OK', 5);
    res.json({ available: true, provider: 'Google Gemini (FREE)', model: GEMINI_MODEL, tier: 'FREE - 1M tokens/day' });
  } catch (e) {
    res.json({ available: false, error: e.message });
  }
});

// POST /api/ai/insight
app.post('/api/ai/insight', async (req, res) => {
  try {
    const { prompt } = req.body;
    if (!prompt) return res.status(400).json({ success: false, error: 'prompt required' });
    const insight = await callGemini(prompt, 200);
    res.json({ success: true, insight, provider: 'gemini-free' });
  } catch (e) {
    res.status(500).json({ success: false, error: e.message, insight: null });
  }
});

// POST /api/ai/chat
app.post('/api/ai/chat', async (req, res) => {
  try {
    const { message, history = [] } = req.body;
    if (!message) return res.status(400).json({ success: false, error: 'message required' });
    const reply = await callGeminiChat(history, message, 400);
    res.json({ success: true, reply, provider: 'gemini-free' });
  } catch (e) {
    res.status(500).json({ success: false, error: e.message });
  }
});

// POST /api/ai/suggest-materials
app.post('/api/ai/suggest-materials', async (req, res) => {
  try {
    const { materials, boundaryConditions } = req.body;
    const result = computeWall(materials, boundaryConditions);
    const prompt = `Current wall: ${materials.map(m => `${m.name}(k=${m.k},t=${m.thickness}mm)`).join(' | ')}
BCs: Ts=${boundaryConditions.T_hot}C, T-inf=${boundaryConditions.T_ambient}C, h=${boundaryConditions.h_conv} W/m2K
Result: q=${result.results.heatFlux_W_per_m2} W/m2, R=${result.results.R_total} m2K/W
Give 2-3 specific improvements with expected % gain in R-value. Max 100 words.`;
    const suggestion = await callGemini(prompt, 180);
    res.json({ success: true, suggestion, currentResult: result.results, provider: 'gemini-free' });
  } catch (e) {
    res.status(500).json({ success: false, error: e.message });
  }
});

// POST /api/ai/optimize
app.post('/api/ai/optimize', async (req, res) => {
  try {
    const { targetFlux = 100, maxThickness = 50, budget = 'medium', temperature = 200 } = req.body;
    const prompt = `Design optimal composite wall:
Target: flux <= ${targetFlux} W/m2, thickness <= ${maxThickness}mm, budget: ${budget}, hot: ${temperature}C, ambient: 50C, h=4 W/m2K
Recommend 2-3 layers (name, k, thickness mm, density). State R-value & expected flux. Max 80 words.`;
    const optimization = await callGemini(prompt, 180);
    res.json({ success: true, optimization, provider: 'gemini-free' });
  } catch (e) {
    res.status(500).json({ success: false, error: e.message });
  }
});

// POST /api/ai/explain
app.post('/api/ai/explain', async (req, res) => {
  try {
    const { parameter, value, context = '' } = req.body;
    if (!parameter) return res.status(400).json({ success: false, error: 'parameter required' });
    const prompt = `Explain for an engineer:
Parameter: ${parameter}, Value: ${value}, Context: ${context}
Physical meaning, if good/bad/typical, one action. Max 80 words.`;
    const explanation = await callGemini(prompt, 120);
    res.json({ success: true, explanation, provider: 'gemini-free' });
  } catch (e) {
    res.status(500).json({ success: false, error: e.message });
  }
});

// ─────────────────────────────────────────────────────────────────
app.listen(PORT, () => {
  console.log(`\n\uD83D\uDD25 Composite Wall CFD API v3 | Port ${PORT}`);
  console.log(`   Pentas Insulations Pvt Ltd`);
  console.log(`   AI: ${GEMINI_API_KEY ? `\u2705 Google Gemini FREE (${GEMINI_MODEL})` : '\u274C Set GEMINI_API_KEY in .env \u2192 https://aistudio.google.com/app/apikey'}`);
  console.log(`   http://localhost:${PORT}\n`);
});
