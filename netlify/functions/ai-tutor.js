exports.handler = async function handler(event) {
  if (event.httpMethod !== 'POST') return json(405, { error: 'Method not allowed' });
  let body;
  try { body = JSON.parse(event.body || '{}'); } catch { return json(400, { error: 'Invalid JSON body' }); }
  const { question = '', subject = 'IB', context = '' } = body;
  if (!question.trim()) return json(400, { error: 'Question is required.' });
  if (!process.env.OPENAI_API_KEY) return json(503, { error: 'OPENAI_API_KEY is not configured. The frontend will use local tutor mode.' });
  const model = process.env.OPENAI_MODEL || 'gpt-5.5-mini';
  const prompt = `You are a calm IB tutor for ${subject}. Answer step by step in simple language. Use markscheme-style wording when relevant. Do not write final coursework for submission; guide the student instead.\n\nLocal study context:\n${context}\n\nStudent question:\n${question}`;
  try {
    const response = await fetch('https://api.openai.com/v1/responses', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${process.env.OPENAI_API_KEY}` },
      body: JSON.stringify({ model, input: prompt, temperature: 0.35, max_output_tokens: 900 })
    });
    if (!response.ok) return json(502, { error: 'OpenAI request failed', detail: await response.text() });
    const data = await response.json();
    return json(200, { answer: extractText(data) });
  } catch (error) { return json(500, { error: error.message || 'Unexpected error' }); }
};
function extractText(data) {
  if (data.output_text) return data.output_text;
  const parts = [];
  for (const item of data.output || []) for (const content of item.content || []) {
    if (content.type === 'output_text' && content.text) parts.push(content.text);
    if (content.text) parts.push(content.text);
  }
  return parts.join('\n') || 'No answer returned.';
}
function json(statusCode, body) { return { statusCode, headers: { 'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*' }, body: JSON.stringify(body) }; }
