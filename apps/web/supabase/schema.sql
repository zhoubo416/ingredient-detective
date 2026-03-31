create extension if not exists pgcrypto;

create table if not exists public.analysis_results (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  source_type text not null check (source_type in ('image', 'manual')),
  image_filename text,
  ingredient_lines jsonb not null default '[]'::jsonb,
  raw_ocr_text text,
  food_name text not null,
  health_score numeric(4, 2) not null,
  result jsonb not null,
  created_at timestamptz not null default timezone('utc', now())
);

create index if not exists analysis_results_user_created_at_idx
  on public.analysis_results (user_id, created_at desc);

alter table public.analysis_results enable row level security;

drop policy if exists "Users can read own analysis results" on public.analysis_results;
create policy "Users can read own analysis results"
  on public.analysis_results
  for select
  to authenticated
  using ((select auth.uid()) = user_id);

drop policy if exists "Users can insert own analysis results" on public.analysis_results;
create policy "Users can insert own analysis results"
  on public.analysis_results
  for insert
  to authenticated
  with check ((select auth.uid()) = user_id);

drop policy if exists "Users can delete own analysis results" on public.analysis_results;
create policy "Users can delete own analysis results"
  on public.analysis_results
  for delete
  to authenticated
  using ((select auth.uid()) = user_id);

-- Add timestamp fields for two-stage analysis tracking
alter table public.analysis_results
add column if not exists quick_analysis_at timestamp default null,
add column if not exists detailed_analysis_at timestamp default null;

-- Create index to query incomplete analyses
create index if not exists idx_analysis_incomplete
on public.analysis_results(user_id, created_at desc)
where detailed_analysis_at is null;
