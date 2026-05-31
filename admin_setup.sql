-- =============================================================================
-- Admin RLS Setup
-- Run this in Supabase SQL Editor AFTER creating your admin user in
-- Supabase Dashboard → Authentication → Users → Add user
-- =============================================================================

-- Enable RLS on all tables
ALTER TABLE events          ENABLE ROW LEVEL SECURITY;
ALTER TABLE locations       ENABLE ROW LEVEL SECURITY;
ALTER TABLE parayana_types  ENABLE ROW LEVEL SECURITY;
ALTER TABLE participants    ENABLE ROW LEVEL SECURITY;
ALTER TABLE event_entries   ENABLE ROW LEVEL SECURITY;

-- Drop any existing policies to avoid conflicts
DROP POLICY IF EXISTS "public read events"          ON events;
DROP POLICY IF EXISTS "public read locations"       ON locations;
DROP POLICY IF EXISTS "public read parayana_types"  ON parayana_types;
DROP POLICY IF EXISTS "public read participants"    ON participants;
DROP POLICY IF EXISTS "public insert participants"  ON participants;
DROP POLICY IF EXISTS "public update participants"  ON participants;
DROP POLICY IF EXISTS "public read entries"         ON event_entries;
DROP POLICY IF EXISTS "public insert entries"       ON event_entries;
DROP POLICY IF EXISTS "public update entries"       ON event_entries;
DROP POLICY IF EXISTS "admin all events"            ON events;
DROP POLICY IF EXISTS "admin all locations"         ON locations;
DROP POLICY IF EXISTS "admin all parayana_types"    ON parayana_types;
DROP POLICY IF EXISTS "admin all participants"      ON participants;
DROP POLICY IF EXISTS "admin all entries"           ON event_entries;

-- ── Public (anon) policies — read-only for reference tables ──────────────────
CREATE POLICY "public read events"         ON events         FOR SELECT USING (true);
CREATE POLICY "public read locations"      ON locations      FOR SELECT USING (true);
CREATE POLICY "public read parayana_types" ON parayana_types FOR SELECT USING (true);

-- ── Public (anon) policies — counter app needs read+write on entries ─────────
CREATE POLICY "public read participants"   ON participants   FOR SELECT USING (true);
CREATE POLICY "public insert participants" ON participants   FOR INSERT WITH CHECK (true);
CREATE POLICY "public update participants" ON participants   FOR UPDATE USING (true);

CREATE POLICY "public read entries"        ON event_entries  FOR SELECT USING (true);
CREATE POLICY "public insert entries"      ON event_entries  FOR INSERT WITH CHECK (true);
CREATE POLICY "public update entries"      ON event_entries  FOR UPDATE USING (true);

-- ── Admin (authenticated) policies — full access to everything ───────────────
CREATE POLICY "admin all events"           ON events         FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "admin all locations"        ON locations      FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "admin all parayana_types"   ON parayana_types FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "admin all participants"     ON participants   FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "admin all entries"          ON event_entries  FOR ALL TO authenticated USING (true) WITH CHECK (true);

-- Grant SELECT on views to authenticated role too
GRANT SELECT ON event_summary   TO authenticated;
GRANT SELECT ON lifetime_stats  TO authenticated;
GRANT ALL    ON ALL TABLES IN SCHEMA public TO authenticated;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO authenticated;
