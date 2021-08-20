CREATE TABLE IF NOT EXISTS role (
  PRIMARY KEY (role_id),
  role_id              integer                     GENERATED ALWAYS AS IDENTITY,
  name                 varchar(30)                 NOT NULL, UNIQUE (name), CHECK (name != '')
);

  

CREATE TABLE IF NOT EXISTS permission (
  PRIMARY KEY (permission_id),
  permission_id        integer                     GENERATED ALWAYS AS IDENTITY,
  name                 varchar(70)                 NOT NULL, UNIQUE (name), CHECK (name != '')
);



CREATE TABLE IF NOT EXISTS resource (
  PRIMARY KEY (resource_id),
  resource_id          integer                     GENERATED ALWAYS AS IDENTITY,
  name                 varchar(30)                 NOT NULL, UNIQUE (name), CHECK (name != '')
);



CREATE TABLE IF NOT EXISTS role_resource_permission (
  PRIMARY KEY (role_id, resource_id, permission_id),
  role_id              integer                     NOT NULL,
  resource_id          integer                     NOT NULL,
  permission_id        integer                     NOT NULL,
  
  FOREIGN KEY (role_id) REFERENCES role (role_id)
    ON DELETE CASCADE,
  FOREIGN KEY (resource_id) REFERENCES resource (resource_id)
    ON DELETE RESTRICT,
  FOREIGN KEY (permission_id) REFERENCES permission (permission_id)
    ON DELETE RESTRICT     
);
CREATE INDEX role_resource_permission__role_idx ON role_resource_permission (role_id ASC);
CREATE INDEX role_resource_permission__resource_idx ON role_resource_permission (resource_id ASC);
CREATE INDEX role_resource_permission__permission_idx ON role_resource_permission (permission_id ASC);



CREATE TABLE IF NOT EXISTS appuser (
  PRIMARY KEY (appuser_id),
  appuser_id           integer                     GENERATED ALWAYS AS IDENTITY,
  role_id              integer                     NOT NULL,
  username             varchar(255)                NOT NULL, UNIQUE (username), CHECK (username != ''),
  -- TODO: verify/edit the appropriate length of the password_hash field. The size of the field should exactly match the size of the output of your key derivation function
  password_hash        varchar(255)                NOT NULL,
  email                varchar(320)                NOT NULL, UNIQUE (email), CHECK (email != ''),
  created_at           timestamp with time zone    DEFAULT CURRENT_TIMESTAMP,
  last_login           timestamp with time zone    DEFAULT CURRENT_TIMESTAMP,
  is_confirmed         boolean        NOT NULL     DEFAULT FALSE, 
  is_deleted           boolean        NOT NULL     DEFAULT FALSE,
  
  FOREIGN KEY (role_id) REFERENCES role (role_id)
    ON DELETE RESTRICT
);
CREATE INDEX appuser__role_id_idx ON appuser (role_id ASC);



CREATE TABLE IF NOT EXISTS setting (
  PRIMARY KEY (setting_id),
  setting_id           integer                     GENERATED ALWAYS AS IDENTITY,
  name                 varchar(60)                 NOT NULL, UNIQUE (name), CHECK (name != ''),
  is_constrained       boolean                     NOT NULL,
  data_type            varchar(15)                 NOT NULL,
  min_value            varchar(10)                 DEFAULT NULL,
  max_value            varchar(10)                 DEFAULT NULL
);



CREATE TABLE IF NOT EXISTS allowed_setting_value (
  PRIMARY KEY (allowed_setting_value_id),
  allowed_setting_value_id    integer           GENERATED ALWAYS AS IDENTITY,
  setting_id                  integer           NOT NULL,
  value                          varchar(15)       NOT NULL,                         
  
  FOREIGN KEY (setting_id) REFERENCES setting (setting_id)
    ON DELETE RESTRICT
);
CREATE INDEX allowed_setting_value__setting_id_idx ON allowed_setting_value (setting_id ASC);



CREATE TABLE IF NOT EXISTS appuser_setting (
  -- NOTE: `user setting_id` is used as PK because there may be settings allowing multiple values
  PRIMARY KEY (user_setting_id),
  user_setting_id               integer            GENERATED ALWAYS AS IDENTITY,
  appuser_id                    integer            NOT NULL,
  setting_id                    integer            NOT NULL, 
  allowed_setting_value_id      integer            DEFAULT NULL,
  unconstrained_value           varchar(15)        DEFAULT NULL, CHECK (unconstrained_value != ''),
  
  FOREIGN KEY (appuser_id) REFERENCES appuser (appuser_id)
    ON DELETE CASCADE,
  FOREIGN KEY (setting_id) REFERENCES setting (setting_id)
    ON DELETE CASCADE,
  FOREIGN KEY (allowed_setting_value_id) REFERENCES allowed_setting_value (allowed_setting_value_id)
    ON DELETE RESTRICT 
);
CREATE INDEX appuser_setting__appuser_id_idx ON appuser_setting (appuser_id ASC);
CREATE INDEX appuser_setting__setting_id_idx ON appuser_setting (setting_id ASC);
CREATE INDEX appuser_setting__allowed_setting_value_id_idx ON appuser_setting (allowed_setting_value_id ASC);



CREATE TABLE IF NOT EXISTS chat_message (
  PRIMARY KEY (chat_message_id),
  chat_message_id      integer                     GENERATED ALWAYS AS IDENTITY,
  appuser_id           integer                     NOT NULL,
  created_at           timestamp with time zone    DEFAULT CURRENT_TIMESTAMP,
  edited_at            timestamp with time zone    DEFAULT CURRENT_TIMESTAMP,
  message              varchar(500)                NOT NULL, CHECK (message != ''),
  
  FOREIGN KEY (appuser_id) REFERENCES appuser (appuser_id)
    ON DELETE RESTRICT
);
CREATE INDEX chat_message__appuser_id_idx ON chat_message (appuser_id ASC);



CREATE TABLE IF NOT EXISTS chat_message_like (
  PRIMARY KEY (chat_message_id, appuser_id),
  chat_message_id      integer                     NOT NULL, 
  appuser_id           integer                     NOT NULL,
  
  FOREIGN KEY (chat_message_id) REFERENCES chat_message (chat_message_id)
    ON DELETE CASCADE,
  FOREIGN KEY (appuser_id) REFERENCES appuser (appuser_id)
    ON DELETE RESTRICT
);



CREATE TABLE IF NOT EXISTS broadcast (
  PRIMARY KEY (broadcast_id),
  broadcast_id         integer                     GENERATED ALWAYS AS IDENTITY,
  title                varchar(70)                 NOT NULL, UNIQUE (title), CHECK (title != ''),
  description          varchar(1000)               DEFAULT NULL, CHECK (description != ''),
  tracklist            varchar(1000)               DEFAULT NULL, CHECK (tracklist != ''),
  start_at             timestamp with time zone    DEFAULT CURRENT_TIMESTAMP,
  end_at               timestamp with time zone    DEFAULT CURRENT_TIMESTAMP,
  top_listener_count   integer                     DEFAULT 0,
  download_url         varchar(2083)               DEFAULT NULL, CHECK (download_url != ''),
  player_html          varchar(300)                DEFAULT NULL, CHECK (player_html != '')
);



CREATE TABLE IF NOT EXISTS appuser_bookmark (
  PRIMARY KEY (appuser_id, broadcast_id),
  appuser_id           integer                     NOT NULL,
  broadcast_id         integer                     NOT NULL,
  
  FOREIGN KEY (appuser_id) REFERENCES appuser (appuser_id)
    ON DELETE CASCADE,
  FOREIGN KEY (broadcast_id) REFERENCES broadcast (broadcast_id)
    ON DELETE CASCADE
);

  

CREATE TABLE IF NOT EXISTS broadcast_like (
  PRIMARY KEY (broadcast_id),
  broadcast_id         integer                     NOT NULL,
  appuser_id           integer                     NOT NULL,
  count                integer                     DEFAULT 0,
  
  FOREIGN KEY (broadcast_id) REFERENCES broadcast (broadcast_id)
    ON DELETE CASCADE,
  FOREIGN KEY (appuser_id) REFERENCES appuser (appuser_id)
    ON DELETE RESTRICT
);



CREATE TABLE IF NOT EXISTS schedule (
  PRIMARY KEY (schedule_id),
  schedule_id          integer                     GENERATED ALWAYS AS IDENTITY,
  start_at             timestamp with time zone    DEFAULT CURRENT_TIMESTAMP,
  end_at               timestamp with time zone    DEFAULT CURRENT_TIMESTAMP
);



---
---
---



INSERT INTO 
  role (name) 
VALUES 
  ('superadmin'), ('admin'), ('listener');



INSERT INTO 
  permission (name) 
VALUES 
  ('create'), ('read'), ('update'), ('delete'), ('partially_update');


  
INSERT INTO 
  resource (name) 
VALUES 
  ('broadcasts'), 
  ('user_bookmarks'), 
  ('user_settings'), 
  ('user_chat_message'), 
  ('user_account'), 
  ('tracklists');
-- ('any_account'); -- FIX: probably you don't need this resouruce cause you will have 'superadmin' granted permissions on user_account, user_setting; verify this
  


INSERT INTO 
  setting (name, is_constrained, data_type) 
VALUES 
  ('send_email_notifications_for_nearest_scheduled_broadcast', true, 'boolean');
  
  
  
INSERT INTO 
  allowed_setting_value (setting_id, value)
VALUES 
  (1, false), (1, true);  