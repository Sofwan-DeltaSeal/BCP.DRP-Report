-- ═══════════════════════════════════════════════════════════════════════════
-- Extend reports table to hold the full report payload, and fix RLS so any
-- logged-in user can read and reporters can insert their own reports.
-- ═══════════════════════════════════════════════════════════════════════════

ALTER TABLE public.reports
  ADD COLUMN IF NOT EXISTS report_time   text,
  ADD COLUMN IF NOT EXISTS reporter_name text,
  ADD COLUMN IF NOT EXISTS issues        int   DEFAULT 0,
  ADD COLUMN IF NOT EXISTS participants  jsonb DEFAULT '[]'::jsonb,
  ADD COLUMN IF NOT EXISTS findings      jsonb DEFAULT '{}'::jsonb;

-- unit is NOT NULL in the schema; reports always send it, so that's fine.

-- ─── RLS: read for any logged-in user, insert own, update by lead/admin ───────
DROP POLICY IF EXISTS "reports_select_all"        ON public.reports;
DROP POLICY IF EXISTS "reports_select_approved"   ON public.reports;
DROP POLICY IF EXISTS "reports_insert_own"        ON public.reports;
DROP POLICY IF EXISTS "reports_update_lead_admin" ON public.reports;

CREATE POLICY "reports_select_all" ON public.reports
  FOR SELECT USING (auth.uid() IS NOT NULL);

CREATE POLICY "reports_insert_own" ON public.reports
  FOR INSERT WITH CHECK (reporter_id = auth.uid());

-- is_lead_or_admin() comes from supabase-fix-recursion.sql
CREATE POLICY "reports_update_lead_admin" ON public.reports
  FOR UPDATE USING (public.is_lead_or_admin());

ALTER TABLE public.reports ENABLE ROW LEVEL SECURITY;
