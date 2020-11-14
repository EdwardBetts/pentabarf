
-- Feature was introduced from conference_id 13 onwards - hard-coded.

CREATE OR REPLACE FUNCTION track_manager_trigger() RETURNS TRIGGER AS $$
  BEGIN
    INSERT INTO auth.account_conference_role
      SELECT distinct a.account_id, a.conference_id, 'devroom'
      FROM conference_track_account a
        LEFT JOIN auth.account_conference_role r
          ON (r.conference_id = a.conference_id AND r.account_id = a.account_id)
        WHERE r.account_id IS NULL;

    DELETE FROM auth.account_conference_role s
      WHERE (s.account_id, s.conference_id, s.conference_role) IN
        (SELECT r.account_id, r.conference_id, r.conference_role
         FROM auth.account_conference_role r 
           LEFT JOIN conference_track_account a  
           ON (a.conference_id = r.conference_id 
               AND a.account_id = r.account_id
               AND r.conference_role = 'devroom')
           WHERE r.conference_id > 12
               AND a.account_id IS NULL)
        AND s.conference_id > 12;
    RETURN NULL;
  END;
$$ LANGUAGE 'plpgsql';

