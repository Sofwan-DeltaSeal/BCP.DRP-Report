-- ─── AUTO-CREATE USER PROFILE ON SIGNUP ──────────────────────────────────────
-- This trigger fires whenever a new user registers via Supabase Auth.
-- It runs with SECURITY DEFINER (bypasses RLS) so the profile is created
-- even before the user confirms their email.

CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path = public
AS $$
BEGIN
  INSERT INTO public.users (id, email, name, role, unit, approved)
  VALUES (
    NEW.id,
    NEW.email,
    COALESCE(NEW.raw_user_meta_data->>'name', split_part(NEW.email, '@', 1)),
    COALESCE(NEW.raw_user_meta_data->>'role', 'reporter'),
    COALESCE(NEW.raw_user_meta_data->>'unit', ''),
    -- Auto-approve admin and lead; reporters need manual approval
    CASE
      WHEN NEW.email IN ('auwabulhafeezabuthalhah@gmail.com', 'cyber.raman24@gmail.com') THEN true
      ELSE false
    END
  )
  ON CONFLICT (id) DO NOTHING;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE PROCEDURE public.handle_new_user();

-- ─── BACKFILL: insert sofwan_roning@kkumail.com if they already signed up ─────
INSERT INTO public.users (id, email, name, role, unit, approved)
SELECT id, email, split_part(email, '@', 1), 'reporter', '', false
FROM auth.users
WHERE email NOT IN (SELECT email FROM public.users)
ON CONFLICT (id) DO NOTHING;

-- ─── ALSO FIX: make sure admin/lead rows have matching auth UUIDs ─────────────
UPDATE public.users
SET id = (SELECT id FROM auth.users WHERE auth.users.email = public.users.email)
WHERE email IN ('auwabulhafeezabuthalhah@gmail.com', 'cyber.raman24@gmail.com')
  AND id != COALESCE((SELECT id FROM auth.users WHERE auth.users.email = public.users.email), id);
