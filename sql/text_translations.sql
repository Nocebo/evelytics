/************************************
 * Text Translation Management
 ************************************/

CREATE TABLE IF NOT EXISTS languages (
    uuidv4 UUID PRIMARY KEY DEFAULT uuid_generate_v4 () UNIQUE,
    language_code VARCHAR(10) NOT NULL UNIQUE,
    language_name VARCHAR(255)
);
comment on table languages is 'Table to store languages for text translation';
comment on column languages.language_code is 'ISO 639-1 code for the language';
comment on column languages.language_name is 'Human friendly name of the language';

-- This table must have something
insert into languages (language_code, language_name) values
('en', 'English'),
('de', 'German'),
('fr', 'French'),
('es', 'Spanish'),
('it', 'Italian'),
('sv', 'Swedish'),
('no', 'Norwegian'),
('fi', 'Finnish'),
('da', 'Danish'),
('pl', 'Polish');

/* Commented out languages
-- ('nl', 'Dutch'),
-- ('pt', 'Portuguese'),
-- ('ru', 'Russian'),
-- ('zh', 'Chinese'),
-- ('ja', 'Japanese'),
-- ('ko', 'Korean'),
-- ('ar', 'Arabic'),
-- ('hi', 'Hindi'),
-- ('bn', 'Bengali'),
-- ('pa', 'Punjabi'),
-- ('ur', 'Urdu'),
-- ('vi', 'Vietnamese'),
-- ('tr', 'Turkish'),
-- ('id', 'Indonesian'),
-- ('th', 'Thai'),
-- ('cs', 'Czech'),
-- ('hu', 'Hungarian'),
-- ('ro', 'Romanian'),
-- ('bg', 'Bulgarian'),
-- ('el', 'Greek'),
-- ('he', 'Hebrew'),
-- ('fa', 'Persian'),
-- ('sw', 'Swahili'),
-- ('tl', 'Tagalog'),
-- ('ms', 'Malay'),
-- ('ta', 'Tamil'),
-- ('te', 'Telugu'),
-- ('kn', 'Kannada'),
-- ('ml', 'Malayalam'),
-- ('gu', 'Gujarati'),
-- ('mr', 'Marathi');
*/

-- Gather all texts from relevant places texts table
CREATE TABLE IF NOT EXISTS texts (
    text_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    system_text VARCHAR(255) NOT NULL UNIQUE
);

-- function that fetches text_id's from entity_type and entity tables
CREATE OR REPLACE FUNCTION fetch_text_ids()
RETURNS TRIGGER AS $$
BEGIN
    -- Insert text_id's of new rows from entity_type table
    IF TG_TABLE_NAME = 'entity_type' THEN
        INSERT INTO texts (text_id, system_text)
        VALUES (NEW.text_id, NEW.entity_type_name)
        ON CONFLICT (system_text) DO NOTHING;
    END IF;

    -- Insert text_id's of new rows from entity table
    IF TG_TABLE_NAME = 'entity' THEN
        INSERT INTO texts (text_id, system_text)
        VALUES (NEW.text_id, NEW.entity_name)
        ON CONFLICT (system_text) DO NOTHING;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- triggers
CREATE TRIGGER fetch_text_ids_trigger
AFTER INSERT OR UPDATE ON entity_type
FOR EACH ROW
EXECUTE FUNCTION fetch_text_ids();

CREATE TRIGGER fetch_text_ids_trigger_entity
AFTER INSERT OR UPDATE ON entity
FOR EACH ROW
EXECUTE FUNCTION fetch_text_ids();

-- Translation table
CREATE TABLE IF NOT EXISTS translations (
    text_id UUID NOT NULL REFERENCES texts(text_id),
    system_text VARCHAR(255) NOT NULL references texts(system_text), -- System text to be translated
    language_code VARCHAR(10) NOT NULL REFERENCES languages(language_code),
    short VARCHAR(10), -- Short translation, max 10 characters
    medium VARCHAR(30), -- Short translation, max 20 characters
    long TEXT,            -- Long translation
    PRIMARY KEY (text_id, language_code)
);
comment on table translations is 'Table to store translations for texts in different languages';
comment on column translations.text_id is 'UUID of the text from texts table';
comment on column translations.system_text is 'System text to be translated, references texts table';
comment on column translations.language_code is 'ISO 639-1 code for the language';
comment on column translations.short is 'Short translation, max 10 characters';
comment on column translations.medium is 'Medium translation, max 30 characters';
comment on column translations.long is 'Long translation, can be longer than 30 characters';

-- Function to insert text_id, system_text, and language_code rows in translations by trigger to crossjoin with language new things in need of translation
CREATE OR REPLACE FUNCTION insert_translation_trigger()
RETURNS TRIGGER AS $$
BEGIN
    -- Insert new text_id, system_text, and language_code rows in translations for all languages
    INSERT INTO translations (text_id, system_text, language_code, short, medium, long)
    SELECT 
        NEW.text_id, 
        NEW.system_text, 
        l.language_code, 
        LEFT(NEW.system_text, 10), 
        LEFT(NEW.system_text, 30), 
        NEW.system_text
    FROM languages l
    ON CONFLICT (text_id, language_code) DO NOTHING;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to insert translations for new texts
CREATE TRIGGER insert_translation_trigger
AFTER INSERT ON texts
FOR EACH ROW
EXECUTE FUNCTION insert_translation_trigger();