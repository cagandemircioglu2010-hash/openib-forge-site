create extension if not exists pgcrypto;

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  email text,
  display_name text,
  target_exam_session text,
  weekly_study_hours integer check (weekly_study_hours between 1 and 80),
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);
create table if not exists public.subjects (
  id uuid primary key default gen_random_uuid(), name text not null, short_name text, group_name text,
  syllabus_version text, support_status text default 'basic support', created_at timestamptz default now()
);
create table if not exists public.topics (
  id uuid primary key default gen_random_uuid(), subject_id uuid references public.subjects(id) on delete cascade,
  name text not null, slug text not null, level text check (level in ('SL','HL','Both')) default 'Both', order_index integer default 0, description text
);
create table if not exists public.subtopics (
  id uuid primary key default gen_random_uuid(), topic_id uuid references public.topics(id) on delete cascade,
  name text not null, order_index integer default 0
);
create table if not exists public.user_subjects (
  id uuid primary key default gen_random_uuid(), user_id uuid references auth.users(id) on delete cascade,
  subject_id uuid references public.subjects(id), level text check (level in ('SL','HL','Core')),
  active boolean default true, created_at timestamptz default now(), unique(user_id, subject_id)
);
create table if not exists public.user_topics (
  id uuid primary key default gen_random_uuid(), user_id uuid references auth.users(id) on delete cascade,
  topic_id uuid references public.topics(id), status text check (status in ('not_started','learning','reviewing','confident')) default 'learning',
  confidence integer check (confidence between 1 and 5), created_at timestamptz default now(), unique(user_id, topic_id)
);
create table if not exists public.questions (
  id uuid primary key default gen_random_uuid(), subject_id uuid references public.subjects(id), topic_id uuid references public.topics(id), subtopic_id uuid references public.subtopics(id),
  level text, difficulty text, question_type text, source_type text, paper_style text, command_term text, marks integer, estimated_seconds integer,
  prompt text not null, choices jsonb, correct_answer text, markscheme text, worked_solution text, common_mistake text, calculator_allowed boolean default true,
  created_at timestamptz default now()
);
create table if not exists public.question_attempts (
  id uuid primary key default gen_random_uuid(), user_id uuid references auth.users(id) on delete cascade,
  question_id uuid references public.questions(id) on delete cascade, answer text, score numeric, max_score numeric, is_correct boolean,
  time_spent_seconds integer, used_hint boolean default false, created_at timestamptz default now()
);
create table if not exists public.notes (
  id uuid primary key default gen_random_uuid(), subject_id uuid references public.subjects(id), topic_id uuid references public.topics(id),
  title text, summary text, content text, key_terms jsonb, formulae jsonb, common_mistakes jsonb, created_at timestamptz default now()
);
create table if not exists public.flashcards (
  id uuid primary key default gen_random_uuid(), subject_id uuid references public.subjects(id), topic_id uuid references public.topics(id),
  front text not null, back text not null, explanation text, difficulty text, created_at timestamptz default now()
);
create table if not exists public.flashcard_reviews (
  id uuid primary key default gen_random_uuid(), user_id uuid references auth.users(id) on delete cascade,
  flashcard_id uuid references public.flashcards(id) on delete cascade, rating text, due_at timestamptz,
  interval_days integer, ease_factor numeric, reviewed_at timestamptz default now()
);
create table if not exists public.study_tasks (
  id uuid primary key default gen_random_uuid(), user_id uuid references auth.users(id) on delete cascade,
  subject_id uuid references public.subjects(id), topic_id uuid references public.topics(id), title text not null, description text,
  task_type text, due_at timestamptz, estimated_minutes integer, completed_at timestamptz, created_at timestamptz default now()
);
create table if not exists public.pomodoro_sessions (
  id uuid primary key default gen_random_uuid(), user_id uuid references auth.users(id) on delete cascade,
  task_id uuid references public.study_tasks(id), duration_minutes integer, completed boolean, created_at timestamptz default now()
);
create table if not exists public.exam_sessions (
  id uuid primary key default gen_random_uuid(), user_id uuid references auth.users(id) on delete cascade,
  subject_id uuid references public.subjects(id), title text, question_ids uuid[], duration_minutes integer,
  score numeric, max_score numeric, completed_at timestamptz, created_at timestamptz default now()
);
create table if not exists public.coursework_reviews (
  id uuid primary key default gen_random_uuid(), user_id uuid references auth.users(id) on delete cascade,
  coursework_type text, subject text, focus text, draft_text text, feedback jsonb, estimated_score numeric, created_at timestamptz default now()
);

alter table public.profiles enable row level security; alter table public.user_subjects enable row level security; alter table public.user_topics enable row level security;
alter table public.question_attempts enable row level security; alter table public.flashcard_reviews enable row level security; alter table public.study_tasks enable row level security;
alter table public.pomodoro_sessions enable row level security; alter table public.exam_sessions enable row level security; alter table public.coursework_reviews enable row level security;
alter table public.subjects enable row level security; alter table public.topics enable row level security; alter table public.subtopics enable row level security;
alter table public.questions enable row level security; alter table public.notes enable row level security; alter table public.flashcards enable row level security;

create policy "public read subjects" on public.subjects for select using (true);
create policy "public read topics" on public.topics for select using (true);
create policy "public read subtopics" on public.subtopics for select using (true);
create policy "public read questions" on public.questions for select using (true);
create policy "public read notes" on public.notes for select using (true);
create policy "public read flashcards" on public.flashcards for select using (true);

create policy "own profile" on public.profiles for all using (auth.uid() = id) with check (auth.uid() = id);
create policy "own user subjects" on public.user_subjects for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "own user topics" on public.user_topics for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "own question attempts" on public.question_attempts for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "own flashcard reviews" on public.flashcard_reviews for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "own study tasks" on public.study_tasks for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "own pomodoros" on public.pomodoro_sessions for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "own exams" on public.exam_sessions for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "own coursework reviews" on public.coursework_reviews for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

insert into public.subjects (name, short_name, group_name, syllabus_version, support_status) values
('Mathematics: Analysis and Approaches','Math AA','Group 5','IB DP current','starter content'),('Mathematics: Applications and Interpretation','Math AI','Group 5','IB DP current','basic support'),('Physics','Physics','Group 4','IB DP current','starter content'),('Chemistry','Chemistry','Group 4','IB DP current','basic support'),('Biology','Biology','Group 4','IB DP current','basic support'),('Computer Science','CS','Group 4','IB DP current','starter content'),('English A Literature','English A Lit','Group 1','IB DP current','basic support'),('English A Language and Literature','English A LangLit','Group 1','IB DP current','basic support'),('Economics','Economics','Group 3','IB DP current','basic support'),('History','History','Group 3','IB DP current','basic support'),('Psychology','Psychology','Group 3','IB DP current','basic support'),('TOK','TOK','Core','IB DP current','basic support'),('Extended Essay','EE','Core','IB DP current','basic support')
on conflict do nothing;
