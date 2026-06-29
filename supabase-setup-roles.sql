-- ─── STEP 1: Add approved column ──────────────────────────────────────────────
-- Run this first in Supabase SQL Editor

ALTER TABLE public.users
  ADD COLUMN IF NOT EXISTS approved boolean NOT NULL DEFAULT false;

-- Admin and Lead are auto-approved when created by SQL
-- Reporters require manual approval by Admin

-- ─── STEP 2: Update RLS — only approved users can read/write reports ──────────
DROP POLICY IF EXISTS "reports_select_all" ON public.reports;
CREATE POLICY "reports_select_approved" ON public.reports
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.users u
      WHERE u.id = auth.uid() AND u.approved = true
    )
  );

-- ─── STEP 3: Set roles for Admin and Lead ─────────────────────────────────────
-- Run AFTER those users have registered via the app

-- auwabulhafeezabuthalhah@gmail.com → Admin
INSERT INTO public.users (id, email, name, role, unit, approved)
VALUES (
  (SELECT id FROM auth.users WHERE email = 'auwabulhafeezabuthalhah@gmail.com'),
  'auwabulhafeezabuthalhah@gmail.com',
  'Admin',
  'admin',
  'ศูนย์เทคโนโลยีสารสนเทศ',
  true
)
ON CONFLICT (email) DO UPDATE
  SET role = 'admin', approved = true;

-- cyber.raman24@gmail.com → Lead
INSERT INTO public.users (id, email, name, role, unit, approved)
VALUES (
  (SELECT id FROM auth.users WHERE email = 'cyber.raman24@gmail.com'),
  'cyber.raman24@gmail.com',
  'Cyber Security Lead',
  'lead',
  'ศูนย์เทคโนโลยีสารสนเทศ',
  true
)
ON CONFLICT (email) DO UPDATE
  SET role = 'lead', approved = true;
