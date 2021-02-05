CREATE OR REPLACE VIEW view_matrix_event_person AS
            SELECT ep.event_id, ep.person_id, ep.event_role, 
		   CASE
		     WHEN
		       ep.remark = 'volunteer'
		       THEN 'volunteer'
		       ELSE ''
                     END as remark,
		   vp.name, vp.email, ac.login_name, pim.im_address as matrix_id, 
		   e.slug, r.conference_room, 
		   cd.conference_day + e.start_time + c.day_change::interval +
                      make_interval(mins=>
			            coalesce(c.timeshift_offset_minutes,0) * 
		        c.f_timeshift_test_enabled::integer * 
		          CASE 
			    WHEN 
			      e.conference_room_id = c.test_conference_room_id 
			      THEN 1 
			      ELSE 0 
			  END 
		      )
		     AS start_datetime,
		   e.duration, e.presentation_length, e.prerecorded
            FROM event_person ep
            JOIN view_person vp ON (vp.person_id = ep.person_id)
            JOIN event e USING (event_id)
            JOIN conference_room r USING (conference_room_id)
	    JOIN conference c ON (c.conference_id = e.conference_id)
            LEFT JOIN conference_day cd USING (conference_day_id)
            LEFT JOIN person_im pim ON (pim.person_id = ep.person_id AND pim.im_type = 'matrix')
            LEFT JOIN view_find_account ac ON (ac.person_id = ep.person_id)
            LEFT JOIN conference_track ct USING (conference_track_id)
            WHERE c.f_matrix_bot_enabled
              AND e.event_state='accepted'
              AND e.event_state_progress ILIKE '%confirmed%'
              AND e.title NOT ILIKE 'CANCELLED%'
	      AND e.public
              AND ep.event_role IN ('speaker', 'moderator', 'coordinator', 'host')
              AND (ep.event_role_state IS NULL OR ep.event_role_state <> 'canceled')
              AND ct.conference_track NOT ILIKE '%certification%';

CREATE OR REPLACE VIEW view_matrix_event_image AS
	SELECT event_id, mime_type, image,
	       md5(image) AS image_hash,
               octet_length(image) AS image_length
	FROM event_image ei
	JOIN view_matrix_event_person USING (event_id)
	GROUP BY event_id, mime_type, image;

