# OpenIB Forge Phase 1 Audit

## Current stack
- The deployed app is a plain HTML/CSS/JavaScript single page app using `index.html`, `styles.css`, and `app.js`.
- Netlify serves the repo root and Netlify Functions from `netlify/functions`.
- Supabase is referenced directly from `app.js` via REST/Auth endpoints; there is no generated Supabase client and no local migrations yet.
- Data is mostly generated in `app.js`; `data/seed.json` is only a small metadata summary.

## Working today
- Local guest state persists to `localStorage` under `openib-forge-v3`.
- Subject/topic selection works and filters generated questions/notes/flashcards.
- Question attempts can be marked complete and affect dashboard/analytics.
- Flashcards can be reviewed and saved locally.
- Planner tasks and Pomodoro run locally.
- Coursework and tutor functions have local fallbacks when AI is unavailable.

## Superficial or weak
- Question content is generated from templates, not curated database rows.
- Supabase cloud persistence writes to a generic `state` table, not the required normalized schema.
- IA/coursework review is rubric-aware locally but still broad; it needs structured JSON and saved reports.
- AI tutor is too generic and is now hidden from primary nav until contextual use is stronger.
- Exam builder creates a printable set but not a full submitted exam session with scoring.

## Visible bugs and fixes required
- The last React/Vite scaffold broke the deployed static app because dependencies could not install; `index.html` no longer loaded `app.js`.
- Navigation labels were too technical (`Question Bank`, `IA / EE Reviewer`) and exposed too many sections.
- Controls were visually compressed in multiple places; button rows need spacing and form labels need block layout.
- Dashboard completion needed explanation so 0% does not look arbitrary.
- Analytics showed a student-facing product audit; this should be hidden from normal students.
- Print/Save PDF was available before an exam existed.

## Minimum serious launch
- Keep a working static app until the React toolchain can install.
- Normalize navigation around Dashboard, Practice, Notes, Flashcards, Exams, Coursework, Planner, Analytics, Settings/account.
- Make guest/cloud state explicit.
- Add the Supabase schema migration so the next backend step has real tables and RLS.
- Use only original IB-style starter content; mark unsupported depth honestly.
