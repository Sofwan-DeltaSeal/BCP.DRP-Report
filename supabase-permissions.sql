-- ═══════════════════════════════════════════════════════════════════════════
-- Clear permission model
--   • Reporter  : sees ONLY their own reports + their own profile
--   • Lead/Admin: see all reports + can approve/reject
--   • Admin ONLY: can delete users and delete reports
-- Requires helper functions from supabase-fix-recursion.sql (is_admin, is_lead_or_admin)
-- ═══════════════════════════════════════════════════════════════════════════

-- ─── USERS: a reporter can read only their own row; admin reads everyone ──────
DROP POLICY IF EXISTS "users_select_all"          ON public.users;
DROP POLICY IF EXISTS "users_select_own_or_admin" ON public.users;
CREATE POLICY "users_select_own_or_admin" ON public.users
  FOR SELECT USING (id = auth.uid() OR public.is_admin());

-- Only admin can delete users
DROP POLICY IF EXISTS "users_delete_admin" ON public.users;
CREATE POLICY "users_delete_admin" ON public.users
  FOR DELETE USING (public.is_admin());

-- ─── REPORTS: reporter sees only own rows; lead/admin see all ────────────────
DROP POLICY IF EXISTS "reports_select_all"          ON public.reports;
DROP POLICY IF EXISTS "reports_select_approved"     ON public.reports;
DROP POLICY IF EXISTS "reports_select_own_or_staff" ON public.reports;
CREATE POLICY "reports_select_own_or_staff" ON public.reports
  FOR SELECT USING (reporter_id = auth.uid() OR public.is_lead_or_admin());

-- Only admin can delete reports (override the earlier lead/admin delete policy)
DROP POLICY IF EXISTS "reports_delete_lead_admin" ON public.reports;
DROP POLICY IF EXISTS "reports_delete_admin"      ON public.reports;
CREATE POLICY "reports_delete_admin" ON public.reports
  FOR DELETE USING (public.is_admin());

ALTER TABLE public.users   ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.reports ENABLE ROW LEVEL SECURITY;
