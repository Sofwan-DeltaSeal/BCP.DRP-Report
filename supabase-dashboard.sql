-- ═══════════════════════════════════════════════════════════════════════════
-- Dashboard: org-wide aggregate stats visible to ALL roles.
-- SECURITY DEFINER → bypasses RLS so reporters see the same overview numbers,
-- while the detailed report LIST stays row-scoped by RLS (reporters = own only).
-- ═══════════════════════════════════════════════════════════════════════════

CREATE OR REPLACE FUNCTION public.get_dashboard_stats()
RETURNS jsonb
LANGUAGE sql SECURITY DEFINER STABLE SET search_path = public
AS $$
  SELECT jsonb_build_object(
    'units',         (SELECT count(DISTINCT unit) FROM reports),
    'total_reports', (SELECT count(*) FROM reports),
    'total_issues',  (SELECT COALESCE(sum(issues),0) FROM reports),
    'pending',       (SELECT count(*) FROM reports WHERE status = 'pending'),

    'aspects', COALESCE((
      SELECT jsonb_object_agg(k, c) FROM (
        SELECT key AS k, COALESCE(sum(jsonb_array_length(value)),0) AS c
        FROM reports r, jsonb_each(r.findings)
        WHERE jsonb_typeof(value) = 'array'
        GROUP BY key
      ) t
    ), '{}'::jsonb),

    'monthly', COALESCE((
      SELECT jsonb_agg(jsonb_build_object('ym', ym, 'count', cnt) ORDER BY ym)
      FROM (
        SELECT to_char(m.mstart,'YYYY-MM') AS ym,
               (SELECT count(*) FROM reports r
                 WHERE r.report_date >= m.mstart::date
                   AND r.report_date <  (m.mstart + interval '1 month')::date) AS cnt
        FROM (
          SELECT date_trunc('month', now()) - (n || ' month')::interval AS mstart
          FROM generate_series(5,0,-1) AS n
        ) m
      ) mm
    ), '[]'::jsonb),

    'recent', COALESCE((
      SELECT jsonb_agg(x) FROM (
        SELECT report_date AS date, unit, issues, status
        FROM reports ORDER BY created_at DESC LIMIT 5
      ) x
    ), '[]'::jsonb)
  );
$$;

GRANT EXECUTE ON FUNCTION public.get_dashboard_stats() TO anon, authenticated;

-- ─── Enable Realtime change-feed on reports (instant dashboard updates) ───────
DO $$ BEGIN
  ALTER PUBLICATION supabase_realtime ADD TABLE public.reports;
EXCEPTION WHEN duplicate_object THEN NULL; END $$;
