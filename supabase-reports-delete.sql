-- Allow lead/admin to delete reports (needed for cleanup + admin moderation)
DROP POLICY IF EXISTS "reports_delete_lead_admin" ON public.reports;
CREATE POLICY "reports_delete_lead_admin" ON public.reports
  FOR DELETE USING (public.is_lead_or_admin());

-- Clean up any leftover probe rows from connection tests
DELETE FROM public.reports WHERE unit = '__probe__';
