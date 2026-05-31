-- =============================================================================
-- PIN verification function
-- Keeps the actual PIN server-side — never exposed to the client
-- =============================================================================
create or replace function verify_event_pin(p_event_id uuid, p_pin text)
returns boolean
language plpgsql
as $$
declare v_pin text;
begin
  select pin into v_pin from events where id = p_event_id;
  if v_pin is null then return true; end if;  -- no PIN = open access
  return v_pin = p_pin;
end;
$$;

grant execute on function verify_event_pin(uuid, text) to anon;

-- =============================================================================
-- Update event_summary view to expose has_pin (boolean) not the PIN itself
-- =============================================================================
create or replace view event_summary as
select
  e.id,
  e.title,
  e.event_date,
  e.is_active,
  l.name                              as location_name,
  l.city                              as location_city,
  pt.name                             as parayana_type,
  count(distinct ee.participant_id)   as participant_count,
  coalesce(sum(ee.count), 0)          as total_recitations,
  e.started_at,
  e.ended_at,
  (e.pin is not null)                 as has_pin
from events e
left join locations l       on l.id = e.location_id
left join parayana_types pt on pt.id = e.parayana_type_id
left join event_entries ee  on ee.event_id = e.id
group by e.id, e.title, e.event_date, e.is_active,
         l.name, l.city, pt.name, e.started_at, e.ended_at, e.pin
order by e.event_date desc;

grant select on event_summary to anon;

-- =============================================================================
-- To set a PIN on an event (run separately with the actual PIN you want):
-- UPDATE events SET pin = '1008' WHERE id = '<your-event-uuid>';
-- To remove a PIN:
-- UPDATE events SET pin = null WHERE id = '<your-event-uuid>';
-- =============================================================================
