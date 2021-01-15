
CREATE TABLE base.conference_person (
  conference_person_id SERIAL NOT NULL,
  conference_id INTEGER NOT NULL,
  person_id INTEGER NOT NULL,
  abstract TEXT,
  description TEXT,
  remark TEXT,
  email TEXT,
  arrived BOOL NOT NULL DEFAULT FALSE,
  reconfirmed BOOL NOT NULL DEFAULT FALSE,
  voucher_number TEXT,
  CONSTRAINT conference_person_email_check CHECK (email ~ E'^[\\w=_.+-]+@([\\w.+_-]+\.)+\\w{2,}$')
);

CREATE TABLE conference_person (
  FOREIGN KEY (conference_id) REFERENCES conference (conference_id) ON UPDATE CASCADE ON DELETE CASCADE,
  FOREIGN KEY (person_id) REFERENCES person (person_id) ON UPDATE CASCADE ON DELETE CASCADE,
  PRIMARY KEY (conference_person_id),
  UNIQUE( conference_id, person_id)
) INHERITS( base.conference_person );

CREATE TABLE log.conference_person (
) INHERITS( base.logging, base.conference_person );

CREATE INDEX log_conference_person_conference_person_id_idx ON log.conference_person( conference_person_id );
CREATE INDEX log_conference_person_log_transaction_id_idx ON log.conference_person( log_transaction_id );

