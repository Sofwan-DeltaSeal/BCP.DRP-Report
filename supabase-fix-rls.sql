-- ─── FIX 1: Allow users to insert their own profile (missing policy) ──────────
DROP POLICY IF EXISTS "users_insert_own" ON public.users;
CREATE POLICY "users_insert_own" ON public.users
  FOR INSERT WITH CHECK (id = auth.uid());

-- ─── FIX 2: Add approved column if not already added ─────────────────────────
ALTER TABLE public.users
  ADD COLUMN IF NOT EXISTS approved boolean NOT NULL DEFAULT false;

-- ─── FIX 3: Force-set Admin and Lead (works even if no profile row exists) ────
INSERT INTO public.users (id, email, name, role, unit, approved)
SELECT id, email, 'Admin', 'admin', 'ศูนย์เทคโนโลยีสารสนเทศ', true
FROM auth.users
WHERE email = 'auwabulhafeezabuthalhah@gmail.com'
ON CONFLICT (email) DO UPDATE SET role = 'admin', approved = true;

INSERT INTO public.users (id, email, name, role, unit, approved)
SELECT id, email, 'Cyber Security Lead', 'lead', 'ศูนย์เทคโนโลยีสารสนเทศ', true
FROM auth.users
WHERE email = 'cyber.raman24@gmail.com'
ON CONFLICT (email) DO UPDATE SET role = 'lead', approved = true;
