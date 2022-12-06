
CREATE TRIGGER related_event_after_insert AFTER INSERT ON event_related FOR STATEMENT EXECUTE PROCEDURE event_related_trigger_insert();

CREATE TRIGGER related_event_after_delete AFTER DELETE ON event_related FOR STATEMENT EXECUTE PROCEDURE event_related_trigger_delete();

CREATE TRIGGER conference_release_after_insert AFTER INSERT ON conference_release FOR EACH ROW EXECUTE PROCEDURE conference_release_trigger_insert();

CREATE TRIGGER custom_fields_trigger BEFORE INSERT OR UPDATE OR DELETE ON custom.custom_fields FOR EACH ROW EXECUTE PROCEDURE custom_field_trigger();

CREATE TRIGGER track_manager_trigger AFTER INSERT OR UPDATE OR DELETE ON conference_track_account FOR EACH STATEMENT EXECUTE PROCEDURE track_manager_trigger();

CREATE TRIGGER event_room_trigger BEFORE UPDATE OF event_state ON event FOR EACH ROW WHEN (NEW.event_state = 'accepted' AND NEW.conference_room_id IS NULL) EXECUTE PROCEDURE event_room_trigger();

