exports.handler = async function handler(event) {
  if (event.httpMethod !== 'POST') return json(405, { error: 'Method not allowed' });
  let body;
  try { body = JSON.parse(event.body || '{}'); } catch { return json(400, { error: 'Invalid JSON body' }); }
  const { type = 'Internal Assessment', focus = 'all', text = '' } = body;
  if (!text || text.trim().length < 100) return json(400, { error: 'Please provide at least 100 characters of draft text.' });
  if (!process.env.OPENAI_API_KEY) return json(503, { error: 'OPENAI_API_KEY is not configured. The frontend will use local rubric review.' });
  const safeText = text.slice(0, 18000);
  const model = process.env.OPENAI_MODEL || 'gpt-5.5-mini';
  const prompt = `You are an IB coursework feedback assistant. Give honest, rubric-aware feedback without writing the student's coursework for them.\n\nCoursework type: ${type}\nReview focus: ${focus}\n\nRules:\n- Do not claim to know the official final mark.\n- Give a readiness estimate only.\n- Do not rewrite the whole draft.\n- Identify strengths, weaknesses, and next edits.\n- Use simple student-friendly language.\n- Mention academic integrity: student must write final work themselves.\n- Format with headings and bullets.\n\nStudent draft:\n\"\"\"\n${safeText}\n\"\"\"`;
  try {
    const response = await fetch('https://api.openai.com/v1/responses', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${process.env.OPENAI_API_KEY}` },
      body: JSON.stringify({ model, input: prompt, temperature: 0.3, max_output_tokens: 1400 })
    });
    if (!response.ok) return json(502, { error: 'OpenAI request failed', detail: await response.text() });
    const data = await response.json();
    return json(200, { html: extractText(data) });
  } catch (error) { return json(500, { error: error.message || 'Unexpected error' }); }
};
function extractText(data) {
  if (data.output_text) return data.output_text;
  const parts = [];
  for (const item of data.output || []) for (const content of item.content || []) {
    if (content.type === 'output_text' && content.text) parts.push(content.text);
    if (content.text) parts.push(content.text);
  }
  return parts.join('\n') || 'No feedback returned.';
}
function json(statusCode, body) { return { statusCode, headers: { 'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*' }, body: JSON.stringify(body) }; }
