CREATE OR REPLACE VIEW view_matrix_bot_export_2021 AS
            SELECT ep.event_id, ep.person_id, ep.event_role, vp.name, vp.email, ac.login_name, pim.im_address as matrix_id, e.slug, r.conference_room
            FROM event_person ep
            JOIN view_person vp ON (vp.person_id = ep.person_id)
            JOIN event e USING (event_id)
            JOIN conference_room r USING (conference_room_id)
            LEFT JOIN person_im pim ON (pim.person_id = ep.person_id AND pim.im_type = 'matrix')
            LEFT JOIN view_find_account ac ON (ac.person_id = ep.person_id)
            LEFT JOIN conference_track ct USING (conference_track_id)
            WHERE e.conference_id=13
              AND e.event_state='accepted'
              AND e.event_state_progress ILIKE '%confirmed%'
              AND e.title NOT ILIKE 'CANCELLED%'
              AND ep.event_role IN ('speaker', 'moderator', 'coordinator', 'host')
              AND (ep.event_role_state IS NULL OR ep.event_role_state <> 'canceled')
              AND ct.conference_track NOT ILIKE '%certification%';

