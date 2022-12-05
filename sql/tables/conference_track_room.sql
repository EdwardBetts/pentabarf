CREATE TABLE base.conference_track_room (
  conference_track_room_id SERIAL NOT NULL,
  conference_id INTEGER NOT NULL,
  conference_track_id INTEGER NOT NULL,
  conference_room_id INTEGER NOT NULL
);

CREATE TABLE conference_track_room (
  FOREIGN KEY (conference_id) REFERENCES conference (conference_id) ON UPDATE CASCADE ON DELETE CASCADE,
  FOREIGN KEY (conference_track_id) REFERENCES conference_track (conference_track_id) ON UPDATE CASCADE ON DELETE CASCADE,
  FOREIGN KEY (conference_room_id) REFERENCES conference_room (conference_room_id) ON UPDATE CASCADE ON DELETE CASCADE,
  UNIQUE (conference_id, conference_track_id, conference_room_id),
  PRIMARY KEY (conference_track_room_id)
) INHERITS (base.conference_track_room);

CREATE TABLE log.conference_track_room (
) INHERITS (base.logging, base.conference_track_room );

CREATE INDEX log_conference_track_room_conference_track_room_id_idx ON log.conference_track_room( conference_track_room_id );
CREATE INDEX log_conference_track_room_log_transaction_id_idx ON log.conference_track_room( log_transaction_id );
