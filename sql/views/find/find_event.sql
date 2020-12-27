
CREATE OR REPLACE VIEW view_find_event AS
  SELECT
    event.event_id,
    event.conference_id,
    event.title,
    event.subtitle,
    event.slug,
    event.abstract,
    event.description,
    event.duration,
    event.event_origin,
    event.conference_track_id,
    event.event_state,
    event.event_state_progress,
    event.event_state || ' ' || event.event_state_progress AS event_state_and_progress,
    event.event_type,
    event.language,
    event.conference_room_id,
    conference_room.conference_room,
    event.conference_day_id,
    conference_day.conference_day,
    conference_day.name AS conference_day_name,
    (event.start_time + conference.day_change)::interval AS start_time,
    event.public,
    conference_track.conference_track,
    event_state_localized.translated,
    event_state_localized.name AS event_state_name,
    event_state_progress_localized.name AS event_state_progress_name,
    event_image.mime_type,
    mime_type.file_extension,
    array_to_string(ARRAY(
      SELECT view_person.person_id
        FROM
          event_person
          INNER JOIN view_person USING (person_id)
        WHERE
          event_person.event_role IN ('speaker','moderator') AND
          event_person.event_role_state = 'confirmed' AND
          event_person.event_id = event.event_id
        ORDER BY view_person.name, event_person.person_id
      ), E'\n'::text) AS speaker_ids,
    array_to_string(ARRAY(
      SELECT view_person.name
        FROM
          event_person
          INNER JOIN view_person USING (person_id)
        WHERE
          event_person.event_role IN ('speaker','moderator') AND
          event_person.event_role_state = 'confirmed' AND
          event_person.event_id = event.event_id
        ORDER BY view_person.name, event_person.person_id
      ), E'\n'::text) AS speakers,
    ARRAY( 
      SELECT person_id 
      FROM event_person
      WHERE 
        event.event_id = event_person.event_id AND 
        event_person.event_role = 'coordinator'
    ) AS coordinators,
    ARRAY( 
      SELECT person_id 
      FROM event_person
      WHERE 
        event.event_id = event_person.event_id AND 
        event_person.event_role = 'host'
    ) AS hosts
  FROM event
    INNER JOIN conference USING (conference_id)
    INNER JOIN event_state_localized USING (event_state)
    INNER JOIN event_state_progress_localized USING (translated,event_state,event_state_progress)
    LEFT OUTER JOIN conference_day USING (conference_day_id)
    LEFT OUTER JOIN conference_track USING (conference_track_id)
    LEFT OUTER JOIN conference_room USING (conference_room_id)
    LEFT OUTER JOIN event_image USING (event_id)
    LEFT OUTER JOIN mime_type USING (mime_type);

