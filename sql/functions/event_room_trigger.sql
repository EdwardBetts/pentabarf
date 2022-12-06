
CREATE OR REPLACE FUNCTION event_room_trigger() RETURNS trigger AS $$
  BEGIN

    IF NEW.conference_room_id is NULL AND NEW.event_state = 'accepted' AND NEW.physical IS TRUE AND NEW.prerecorded IS FALSE AND (SELECT COUNT(*) FROM conference_track_room WHERE conference_id = NEW.conference_id AND conference_track_id = NEW.conference_track_id) = 1 THEN
	NEW.conference_room_id = (SELECT conference_room_id FROM conference_track_room WHERE conference_id = NEW.conference_id AND conference_track_id = NEW.conference_track_id);
    END IF;

    RETURN NEW;

  END;
$$ LANGUAGE plpgsql;

