-- ═══════════════════════════════════════════════════════════════════════════
-- FIX: RLS infinite recursion on public.users
-- The old "users_admin_write" policy queried public.users from inside a policy
-- ON public.users → infinite recursion → every SELECT on users failed.
-- Solution: use SECURITY DEFINER helper functions that bypass RLS.
-- ═══════════════════════════════════════════════════════════════════════════

-- ─── Helper functions (SECURITY DEFINER bypasses RLS, breaks the recursion) ───
CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS boolean LANGUAGE sql SECURITY DEFINER STABLE SET search_path = public
AS $$ SELECT EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role = 'admin') $$;

CREATE OR REPLACE FUNCTION public.is_lead_or_admin()
RETURNS boolean LANGUAGE sql SECURITY DEFINER STABLE SET search_path = public
AS $$ SELECT EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role IN ('lead','admin')) $$;

-- ─── USERS policies: drop the recursive one, rebuild cleanly ──────────────────
DROP POLICY IF EXISTS "users_admin_write"  ON public.users;
DROP POLICY IF EXISTS "users_select_all"   ON public.users;
DROP POLICY IF EXISTS "users_insert_own"   ON public.users;
DROP POLICY IF EXISTS "users_update_admin" ON public.users;

-- Anyone authenticated can read users (needed for admin panel + participant lookup)
CREATE POLICY "users_select_all" ON public.users
  FOR SELECT USING (true);

-- A user can insert their own profile row
CREATE POLICY "users_insert_own" ON public.users
  FOR INSERT WITH CHECK (id = auth.uid());

-- Only admins can update users (approve / change role) — uses helper, no recursion
CREATE POLICY "users_update_admin" ON public.users
  FOR UPDATE USING (public.is_admin());

-- ─── REPORTS policies: also rebuild update policy without recursion ───────────
DROP POLICY IF EXISTS "reports_update_lead_admin" ON public.reports;
CREATE POLICY "reports_update_lead_admin" ON public.reports
  FOR UPDATE USING (public.is_lead_or_admin());

DROP POLICY IF EXISTS "drills_insert_lead_admin" ON public.drills;
CREATE POLICY "drills_insert_lead_admin" ON public.drills
  FOR INSERT WITH CHECK (public.is_lead_or_admin());

-- ─── Make sure RLS is on ──────────────────────────────────────────────────────
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
