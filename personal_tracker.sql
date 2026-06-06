-- =============================================================================
-- Personal Daily Chant Tracker
-- Run in Supabase SQL Editor
-- =============================================================================

-- 1. Add PIN column to participants (for personal tracker login)
ALTER TABLE participants ADD COLUMN IF NOT EXISTS pin text;

-- 2. Personal chants table
CREATE TABLE IF NOT EXISTS personal_chants (
  id               uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  participant_id   uuid NOT NULL REFERENCES participants(id) ON DELETE CASCADE,
  parayana_type_id uuid NOT NULL REFERENCES parayana_types(id),
  chant_date       date NOT NULL DEFAULT CURRENT_DATE,
  count            integer NOT NULL DEFAULT 0 CHECK (count >= 0),
  updated_at       timestamptz DEFAULT now(),
  UNIQUE(participant_id, parayana_type_id, chant_date)
);

-- RLS for personal_chants
ALTER TABLE personal_chants ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "anon read personal_chants"   ON personal_chants;
DROP POLICY IF EXISTS "anon insert personal_chants" ON personal_chants;
DROP POLICY IF EXISTS "anon update personal_chants" ON personal_chants;

CREATE POLICY "anon read personal_chants"   ON personal_chants FOR SELECT USING (true);
CREATE POLICY "anon insert personal_chants" ON personal_chants FOR INSERT WITH CHECK (true);
CREATE POLICY "anon update personal_chants" ON personal_chants FOR UPDATE USING (true);

-- Grant SELECT to anon
GRANT SELECT ON personal_chants TO anon;
GRANT ALL    ON personal_chants TO authenticated;

-- =============================================================================
-- 3. Register a new chanter (or claim existing participant record)
-- Returns: JSON { id: uuid, claimed: bool }
--   claimed=true  → participant existed from an event but had no PIN; PIN now set
--   claimed=false → brand new participant created
-- =============================================================================
CREATE OR REPLACE FUNCTION register_chanter(p_name text, p_pin text)
RETURNS json LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_id  uuid;
  v_pin text;
BEGIN
  IF length(trim(p_pin)) < 4 THEN
    RAISE EXCEPTION 'PIN must be at least 4 digits';
  END IF;

  SELECT id, pin INTO v_id, v_pin
  FROM participants
  WHERE lower(trim(name)) = lower(trim(p_name));

  IF FOUND THEN
    IF v_pin IS NOT NULL THEN
      RAISE EXCEPTION 'Name already registered — please log in instead';
    ELSE
      -- Existing participant (added via event) — claim the account with a PIN
      UPDATE participants SET pin = p_pin WHERE id = v_id;
      RETURN json_build_object('id', v_id, 'claimed', true);
    END IF;
  END IF;

  INSERT INTO participants(name, pin) VALUES (trim(p_name), p_pin) RETURNING id INTO v_id;
  RETURN json_build_object('id', v_id, 'claimed', false);
END;
$$;

-- =============================================================================
-- 4. Login — returns participant UUID on success, NULL on wrong name/PIN
-- =============================================================================
CREATE OR REPLACE FUNCTION login_chanter(p_name text, p_pin text)
RETURNS uuid LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_id  uuid;
  v_pin text;
BEGIN
  SELECT id, pin INTO v_id, v_pin
  FROM participants
  WHERE lower(trim(name)) = lower(trim(p_name));

  IF NOT FOUND THEN RETURN NULL; END IF;
  IF v_pin IS NULL OR v_pin <> p_pin THEN RETURN NULL; END IF;
  RETURN v_id;
END;
$$;

-- =============================================================================
-- 5. Increment / decrement a chant count for a specific day
--    Uses delta (+1 / -1) like the event counter.
--    Returns the new count.
-- =============================================================================
CREATE OR REPLACE FUNCTION log_personal_chant(
  p_participant_id   uuid,
  p_parayana_type_id uuid,
  p_date             date,
  p_delta            integer
)
RETURNS integer LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE v_count integer;
BEGIN
  INSERT INTO personal_chants(participant_id, parayana_type_id, chant_date, count)
  VALUES (p_participant_id, p_parayana_type_id, p_date, greatest(0, p_delta))
  ON CONFLICT (participant_id, parayana_type_id, chant_date)
  DO UPDATE SET
    count      = greatest(0, personal_chants.count + p_delta),
    updated_at = now()
  RETURNING count INTO v_count;
  RETURN v_count;
END;
$$;

-- =============================================================================
-- 6. Set exact count (for direct numeric input)
-- =============================================================================
CREATE OR REPLACE FUNCTION set_personal_chant(
  p_participant_id   uuid,
  p_parayana_type_id uuid,
  p_date             date,
  p_count            integer
)
RETURNS void LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  INSERT INTO personal_chants(participant_id, parayana_type_id, chant_date, count)
  VALUES (p_participant_id, p_parayana_type_id, p_date, greatest(0, p_count))
  ON CONFLICT (participant_id, parayana_type_id, chant_date)
  DO UPDATE SET count = greatest(0, p_count), updated_at = now();
END;
$$;

-- Grant execute to anon
GRANT EXECUTE ON FUNCTION register_chanter   TO anon;
GRANT EXECUTE ON FUNCTION login_chanter      TO anon;
GRANT EXECUTE ON FUNCTION log_personal_chant TO anon;
GRANT EXECUTE ON FUNCTION set_personal_chant TO anon;
