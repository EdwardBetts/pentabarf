CREATE OR REPLACE VIEW view_report_devroom_managers AS
  SELECT t.conference_id, 
    conference_track, 
    concat(conference_track_mail_alias, '@fosdem.org') AS mail_alias, 
    array_to_string(array_agg(a.email), ', ') AS alias_expansion,
    array_to_string(array_agg(concat(p.first_name, ' ', p.last_name, ' <', a.email,'>')), ', ') AS devroom_managers_contacts,
    array_to_string(array_agg(p.email), ', ') AS person_emails,
    array_to_string(array_agg(login_name), ', ') AS login_names
  FROM conference_track_account
  JOIN conference_track t USING (conference_track_id) 
  JOIN auth.account a USING (account_id) 
  JOIN person p USING (person_id)
  GROUP BY conference_track, conference_track_mail_alias, t.conference_id 
  ORDER BY conference_track;

