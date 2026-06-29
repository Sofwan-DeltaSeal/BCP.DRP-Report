-- BCP/DRP Reporting System — Supabase Schema
-- Run this in the Supabase SQL Editor at:
-- https://supabase.com/dashboard/project/<project-id>/editor

-- Enable UUID extension
create extension if not exists "uuid-ossp";

-- ─── USERS ───────────────────────────────────────────────────────────────────
create table if not exists public.users (
  id          uuid primary key default uuid_generate_v4(),
  email       text unique not null,
  name        text not null,
  role        text not null check (role in ('reporter','lead','admin')),
  unit        text,
  created_at  timestamptz default now()
);

-- ─── DRILLS ──────────────────────────────────────────────────────────────────
create table if not exists public.drills (
  id          uuid primary key default uuid_generate_v4(),
  title       text not null,
  drill_date  date not null,
  scenario    text,
  created_by  uuid references public.users(id),
  created_at  timestamptz default now()
);

-- ─── REPORTS ─────────────────────────────────────────────────────────────────
create table if not exists public.reports (
  id            uuid primary key default uuid_generate_v4(),
  drill_id      uuid references public.drills(id),
  reporter_id   uuid references public.users(id),
  unit          text not null,
  report_date   date not null default current_date,
  summary       text,
  status        text not null default 'pending' check (status in ('pending','approved','rejected')),
  reviewer_id   uuid references public.users(id),
  review_note   text,
  reviewed_at   timestamptz,
  created_at    timestamptz default now()
);

-- ─── PARTICIPANTS ─────────────────────────────────────────────────────────────
create table if not exists public.participants (
  id          uuid primary key default uuid_generate_v4(),
  report_id   uuid references public.reports(id) on delete cascade,
  name        text not null,
  role_label  text,
  position    text,
  created_at  timestamptz default now()
);

-- ─── FINDINGS ─────────────────────────────────────────────────────────────────
create table if not exists public.findings (
  id          uuid primary key default uuid_generate_v4(),
  report_id   uuid references public.reports(id) on delete cascade,
  aspect      text not null check (aspect in ('pr','dr','staff','bcp','other')),
  description text not null,
  severity    text default 'medium' check (severity in ('low','medium','high')),
  created_at  timestamptz default now()
);

-- ─── ROW-LEVEL SECURITY ───────────────────────────────────────────────────────
alter table public.users       enable row level security;
alter table public.drills      enable row level security;
alter table public.reports     enable row level security;
alter table public.participants enable row level security;
alter table public.findings    enable row level security;

-- Drop existing policies before recreating
drop policy if exists "users_select_all"            on public.users;
drop policy if exists "users_admin_write"           on public.users;
drop policy if exists "reports_select_all"          on public.reports;
drop policy if exists "reports_insert_own"          on public.reports;
drop policy if exists "reports_update_lead_admin"   on public.reports;
drop policy if exists "participants_select"         on public.participants;
drop policy if exists "participants_insert"         on public.participants;
drop policy if exists "findings_select"             on public.findings;
drop policy if exists "findings_insert"             on public.findings;
drop policy if exists "drills_select"               on public.drills;
drop policy if exists "drills_insert_lead_admin"    on public.drills;

-- Users can read all users (for participant lookup)
create policy "users_select_all" on public.users
  for select using (true);

-- Only admins can insert/update users
create policy "users_admin_write" on public.users
  for all using (
    exists (select 1 from public.users u where u.id = auth.uid() and u.role = 'admin')
  );

-- All authenticated users can read reports
create policy "reports_select_all" on public.reports
  for select using (auth.role() = 'authenticated');

-- Reporters can insert their own reports
create policy "reports_insert_own" on public.reports
  for insert with check (reporter_id = auth.uid());

-- Leads and admins can update reports (approval/rejection)
create policy "reports_update_lead_admin" on public.reports
  for update using (
    exists (select 1 from public.users u where u.id = auth.uid() and u.role in ('lead','admin'))
  );

-- Participants and findings follow report access
create policy "participants_select" on public.participants
  for select using (auth.role() = 'authenticated');

create policy "participants_insert" on public.participants
  for insert with check (
    exists (select 1 from public.reports r where r.id = report_id and r.reporter_id = auth.uid())
  );

create policy "findings_select" on public.findings
  for select using (auth.role() = 'authenticated');

create policy "findings_insert" on public.findings
  for insert with check (
    exists (select 1 from public.reports r where r.id = report_id and r.reporter_id = auth.uid())
  );

create policy "drills_select" on public.drills
  for select using (auth.role() = 'authenticated');

create policy "drills_insert_lead_admin" on public.drills
  for insert with check (
    exists (select 1 from public.users u where u.id = auth.uid() and u.role in ('lead','admin'))
  );

-- ─── SAMPLE DATA ─────────────────────────────────────────────────────────────
-- Insert via Supabase Auth first, then reference auth.users.id here if needed.
-- The app currently uses local demo data; connect Supabase when ready.
