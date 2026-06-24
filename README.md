# OpenIB Forge Site

Free IB revision platform with a dashboard, subject map, question bank, notes, flashcards, IA/EE/TOK reviewer, AI tutor, planner, Pomodoro timer, exam builder, Supabase progress saving, and Netlify functions.

## Deployment

This repository is ready for Netlify. Build settings are in `netlify.toml`.

- Publish directory: `.`
- Functions directory: `netlify/functions`

## Environment variables

For optional AI features in Netlify, add:

- `OPENAI_API_KEY`
- `OPENAI_MODEL` (optional)

The frontend includes Supabase public URL and anon key for client-side auth/state syncing.
