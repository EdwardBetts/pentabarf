CREATE TABLE base.conference_track_account (
  conference_track_account_id SERIAL NOT NULL,
  conference_id INTEGER NOT NULL,
  conference_track_id INTEGER NOT NULL,
  account_id INTEGER NOT NULL
);

CREATE TABLE conference_track_account (
  FOREIGN KEY (conference_id) REFERENCES conference (conference_id) ON UPDATE CASCADE ON DELETE CASCADE,
  FOREIGN KEY (conference_track_id) REFERENCES conference_track (conference_track_id) ON UPDATE CASCADE ON DELETE CASCADE,
  FOREIGN KEY (account_id) REFERENCES auth.account (account_id) ON UPDATE CASCADE ON DELETE CASCADE,
  UNIQUE (conference_id, conference_track_id, account_id),
  PRIMARY KEY (conference_track_account_id)
) INHERITS (base.conference_track_account);

CREATE TABLE log.conference_track_account (
) INHERITS (base.logging, base.conference_track_account );

CREATE INDEX log_conference_track_account_conference_track_account_id_idx ON log.conference_track_account( conference_track_account_id );
CREATE INDEX log_conference_track_account_log_transaction_id_idx ON log.conference_track_account( log_transaction_id );
