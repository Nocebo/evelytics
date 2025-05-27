/*
 * Entity Management System
 * This script creates tables and functions to manage entities in a manufacturing system.
 * TODO: How to handle changes with rollbacks and partitions
 */

-- Will drop everything in the schema
DROP SCHEMA public CASCADE;
-- Recreate the schema
CREATE SCHEMA public;

/************************************
 * Extensions
 ************************************/
-- Enable the uuid-ossp extension for UUID generation
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
-- Enable the ltree extension for hierarchical data management
CREATE EXTENSION IF NOT EXISTS ltree;
-- Enable the pgcrypto extension for cryptographic functions
CREATE EXTENSION IF NOT EXISTS pgcrypto;

/************************************
 * Entity Type Management 
 ************************************/

CREATE TABLE IF NOT EXISTS entity_type (
    uuidv4 UUID PRIMARY KEY DEFAULT uuid_generate_v4 (),
    entity_type_name VARCHAR(255) NOT NULL UNIQUE,
    entity_type_code VARCHAR(4) NOT NULL UNIQUE CHECK (UPPER(entity_type_code) ~ '^[A-Z]+$'), -- TODO: This does not work it seems
    description TEXT,
    text_id UUID NOT NULL DEFAULT uuid_generate_v4 (),
    default_config JSONB
);

comment on table entity_type is 'Table to define different types of entities in the system';
comment on column entity_type.entity_type_name is 'System human friendly name of the entity type';
comment on column entity_type.description is 'Description of the entity type';
comment on column entity_type.default_config is 'Default configuration for the entity type in JSON format';

/************************************
 * Entity Management 
 ************************************/

CREATE TABLE IF NOT EXISTS entity (
    uuidv4 UUID PRIMARY KEY DEFAULT uuid_generate_v4 (),
    entity_name VARCHAR(255) NOT NULL UNIQUE,
    uuidv4_entity_type UUID NOT NULL REFERENCES entity_type(uuidv4),
    text_id UUID NOT NULL DEFAULT uuid_generate_v4 (),
    extra_config JSONB
);

comment on table entity is 'Table to store entities in the system';
comment on column entity.entity_name is 'System human friendly name of the entity';
comment on column entity.uuidv4_entity_type is 'UUID of the entity type from entity_type table';
comment on column entity.extra_config is 'Additional configuration for the entity in JSON format, can be combined with jsonb_concat with the default_config from entity_type';


/************************************
 * Get UUID Functions
 ************************************/

-- TODO: Can't these be chained?

-- Type UUID
create function get_uuid_entity_type_by_type_name(inStr VARCHAR)
returns UUID as $$
declare
    entity_type_uuid UUID;
begin
    select uuidv4 into entity_type_uuid
    from entity_type
    where entity_type_name = $1;
    
    if not found then
        raise exception 'Entity type name % not found', $1;
    end if;

    return entity_type_uuid;
end;
$$ language plpgsql;

-- Entity UUID
create function get_uuid_entity_by_entity_name(inStr VARCHAR)
returns UUID as $$
declare
    entity_uuid UUID;
begin
    select uuidv4 into entity_uuid
    from entity
    where entity_name = $1;
    
    if not found then
        raise exception 'Entity name % not found, no entity UUID could be retrieved', $1;
    end if;

    return entity_uuid;
end;
$$ language plpgsql;

-- Type UUID by Entity Name
CREATE FUNCTION get_uuid_entity_type_by_entity_name(inStr VARCHAR)
RETURNS UUID AS $$
DECLARE
    entity_type_uuid UUID;
BEGIN
    SELECT e.uuidv4_entity_type INTO entity_type_uuid
    FROM entity e
    WHERE e.entity_name = inStr;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Entity name % not found, no entity type UUID could be retrieved', inStr;
    END IF;

    RETURN entity_type_uuid;
END;
$$ LANGUAGE plpgsql;

-- Type UUID by Entity UUID
CREATE FUNCTION get_uuid_entity_type_by_entity_uuid(inUUID UUID)
RETURNS UUID AS $$
DECLARE
    entity_type_uuid UUID;
BEGIN
    SELECT e.uuidv4_entity_type INTO entity_type_uuid
    FROM entity e
    WHERE e.uuidv4 = inUUID;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Entity UUID % not found, no entity type UUID could be retrieved', inUUID;
    END IF;

    RETURN entity_type_uuid;
END;
$$ LANGUAGE plpgsql;

-- Type Name by Entity UUID
CREATE FUNCTION get_entity_type_name_by_entity_uuid(inUUID UUID)
RETURNS VARCHAR AS $$
DECLARE
    entity_type_name VARCHAR;
BEGIN
    SELECT et.entity_type_name INTO entity_type_name
    FROM entity e
    JOIN entity_type et ON e.uuidv4_entity_type = et.uuidv4
    WHERE e.uuidv4 = inUUID;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Entity UUID % not found, no entity type name could be retrieved', inUUID;
    END IF;

    RETURN entity_type_name;
END;
$$ LANGUAGE plpgsql;


/************************************
 * Entity Relation Constraint Management 
 ************************************/

 CREATE table entity_relation_constraints (
    id_hash_types VARCHAR(64) GENERATED ALWAYS AS (md5(parent_type::text || child_type::text)) STORED,
    parent_type UUID NOT NULL REFERENCES entity_type(uuidv4),
    parent_type_name VARCHAR(255) NOT NULL references entity_type(entity_type_name),
    child_type UUID NOT NULL REFERENCES entity_type(uuidv4),
    child_type_name VARCHAR(255) NOT NULL references entity_type(entity_type_name),
    active BOOLEAN DEFAULT FALSE
);

comment on table entity_relation_constraints is 'Table to store constraints on entity relations based on entity types';
comment on column entity_relation_constraints.id_hash_types is 'Hash of the parent and child entity types, used to quickly check if the relation is allowed';
comment on column entity_relation_constraints.active is 'Flag to indicate if the relation constraint is active';
comment on column entity_relation_constraints.parent_type is 'UUID of the parent entity type from entity_type table';
comment on column entity_relation_constraints.child_type is 'UUID of the child entity type from entity_type table';


-- Need a trigger that adds new entries to entity_relation_constraints when new entity types are added
CREATE OR REPLACE FUNCTION add_entity_type_constraints()
RETURNS TRIGGER AS $$
BEGIN
    -- Ensure only one entry exists where parent and child are the same
    IF NEW.uuidv4 NOT IN (
        SELECT parent_type FROM entity_relation_constraints WHERE parent_type = child_type
    ) THEN
        INSERT INTO entity_relation_constraints (parent_type, parent_type_name, child_type, child_type_name)
        VALUES (NEW.uuidv4, NEW.entity_type_name, NEW.uuidv4, NEW.entity_type_name);
    END IF;

    -- Add other constraints
    INSERT INTO entity_relation_constraints (parent_type, parent_type_name, child_type, child_type_name)
    SELECT NEW.uuidv4 AS parent_type,
           NEW.entity_type_name AS parent_type_name,
           et.uuidv4 AS child_type,
           et.entity_type_name AS child_type_name
    FROM entity_type et
    WHERE NOT EXISTS (
        SELECT 1 FROM entity_relation_constraints erc
        WHERE erc.parent_type = NEW.uuidv4 AND erc.child_type = et.uuidv4
    )
    UNION ALL
    SELECT et.uuidv4 AS parent_type,
           et.entity_type_name AS parent_type_name,
           NEW.uuidv4 AS child_type,
           NEW.entity_type_name AS child_type_name
    FROM entity_type et
    WHERE NOT EXISTS (
        SELECT 1 FROM entity_relation_constraints erc
        WHERE erc.parent_type = et.uuidv4 AND erc.child_type = NEW.uuidv4
    );

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER add_entity_type_constraints_trigger
AFTER INSERT ON entity_type
FOR EACH ROW
EXECUTE FUNCTION add_entity_type_constraints();

/************************************
 * Entity Relation Management 
 ************************************/

CREATE TABLE IF NOT EXISTS entity_relation (
    uuidv4 UUID PRIMARY KEY DEFAULT uuid_generate_v4 (),
    id_hash_types VARCHAR(64),
    parent_entity UUID NOT NULL REFERENCES entity(uuidv4),
    child_entity UUID NOT NULL REFERENCES entity(uuidv4),
    sequence_number INTEGER DEFAULT 0
);

comment on table entity_relation is 'Table to store relations between entities in the system';
comment on column entity_relation.id_hash_types is 'Hash of the parent and child entity types, used to quickly check if the relation is allowed by entity_relation_constraints';
comment on column entity_relation.uuidv4 is 'UUID of the entity relation';
comment on column entity_relation.parent_entity is 'UUID of the parent entity from entity table';
comment on column entity_relation.child_entity is 'UUID of the child entity from entity table';

-- Function to add hash based on parent_entity_type and child_entity_type and stop if the relation is not allowed by entity_relation_constraints
CREATE OR REPLACE FUNCTION add_hash_to_entity_relation()
RETURNS TRIGGER AS $$
BEGIN
    -- Check if the relation is allowed by entity_relation_constraints
    IF NOT EXISTS (
        SELECT 1 FROM entity_relation_constraints erc
        WHERE erc.parent_type = (SELECT uuidv4_entity_type FROM entity WHERE uuidv4 = NEW.parent_entity)
          AND erc.child_type = (SELECT uuidv4_entity_type FROM entity WHERE uuidv4 = NEW.child_entity)
          AND erc.active = TRUE
    ) THEN
        RAISE EXCEPTION 'Relation between % and % is not allowed due to no active condition in entity_relation_constraints between % and %', NEW.parent_entity, NEW.child_entity, get_entity_type_name_by_entity_uuid(NEW.parent_entity), get_entity_type_name_by_entity_uuid(NEW.child_entity);
    END IF;

    -- Add hash based on parent_entity_type and child_entity_type
    NEW.id_hash_types := md5(
        (SELECT entity_type_name FROM entity_type WHERE uuidv4 = (SELECT uuidv4_entity_type FROM entity WHERE uuidv4 = NEW.parent_entity)) ||
        (SELECT entity_type_name FROM entity_type WHERE uuidv4 = (SELECT uuidv4_entity_type FROM entity WHERE uuidv4 = NEW.child_entity))
    );

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;
CREATE TRIGGER add_hash_to_entity_relation_trigger
AFTER INSERT OR UPDATE ON entity_relation
FOR EACH ROW
EXECUTE FUNCTION add_hash_to_entity_relation();


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
    SELECT NEW.text_id, NEW.system_text, l.language_code, NEW.system_text, NEW.system_text, NEW.system_text
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

-- Function to call for text in language
CREATE OR REPLACE FUNCTION get_translation_by_text_id(in_text_id UUID, in_language_code VARCHAR(10))
RETURNS TEXT AS $$
DECLARE
    translation TEXT;
BEGIN
    SELECT long INTO translation
    FROM translations
    WHERE text_id = in_text_id AND language_code = in_language_code;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Translation for text_id % and language_code % not found', in_text_id, in_language_code;
    END IF;

    RETURN translation;
END;
$$ LANGUAGE plpgsql;

-- Function to call for text in language by system text
CREATE OR REPLACE FUNCTION get_translation_by_system_text(in_system_text VARCHAR, in_language_code VARCHAR(10))
RETURNS TEXT AS $$
DECLARE
    translation TEXT;
BEGIN
    SELECT long INTO translation
    FROM translations
    WHERE system_text = in_system_text AND language_code = in_language_code;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Translation for system_text % and language_code % not found', in_system_text, in_language_code;
    END IF;

    RETURN translation;
END;
$$ LANGUAGE plpgsql;


-- IMPROVEMENTS
-- TODO: Add clousure table on entity_relation to make reads easier. Alternatively use ltree. Alternatively function with recursive CTEs to get the full tree of entities.
-- TODO: Make sure to handle circular references in the entity_relation table.
-- TODO: Make sure to handle the case where an entity is deleted and all its relations are deleted as well.
-- TODO: Parallelism in workcenters for example. Maybe need the mermaid rework.

-- ADDITIONAL FEATURES
-- TODO: Schema
-- TODO: Text translation
-- TODO: Views
-- TODO: Mermaid interface for entity relations, maybe requires rebuild
-- TODO: Events
-- TODO: Durations
-- TODO: Gitlike rollbacks for changes, change tracking



/************************************
 * Views
 ************************************/



/************************************
 * Test Data
 ************************************/

insert into entity_type (entity_type_name, entity_type_code, description, default_config) values
('conveyor_belt', 'CNVB', 'A conveyor belt in the manufacturing system', '{"speed": "normal", "length": "standard"}'),
('order', 'ORDR', 'An order in the manufacturing system', '{"status": "pending", "priority": "normal"}'),
('workcenter', 'WRKC', 'A workcenter in the manufacturing system', '{"location": ""}'),
('tact_circuit', 'TCTC', 'A tact circuit in the manufacturing system', '{"length":""}'),
('production_line', 'PLIN', 'A production line in the manufacturing system', '{"capacity":""}'),
('machine', 'MACH', 'A machine in the manufacturing system', '{"model": ""}'),
('sensor', 'SENS', 'A sensor in the manufacturing system', '{"unit": ""}');

insert into entity (entity_name, uuidv4_entity_type, extra_config) values
('Workcenter1', get_uuid_entity_type_by_type_name('workcenter'), '{"location": "Factory A"}'),
('Workcenter2', get_uuid_entity_type_by_type_name('workcenter'), '{"location": "Factory A"}'),
('Workcenter3', get_uuid_entity_type_by_type_name('workcenter'), '{"location": "Factory B"}'),
('ConveyorBelt1', get_uuid_entity_type_by_type_name('conveyor_belt'), '{"speed": "fast", "length": "long"}'),
('Order1', get_uuid_entity_type_by_type_name('order'), '{"status": "in_progress", "priority": "high"}'),
('TactCircuit1', get_uuid_entity_type_by_type_name('tact_circuit'), '{"length": 100}'),
('ProductionLine1', get_uuid_entity_type_by_type_name('production_line'), '{"capacity": 500}'),
('Machine1', get_uuid_entity_type_by_type_name('machine'), '{"model": "X1000"}'),
('Sensor1', get_uuid_entity_type_by_type_name('sensor'), '{"type": "pressure"}'),
('Sensor3', get_uuid_entity_type_by_type_name('sensor'), '{"type": "vibration"}');

-- Text translation check
select * from translations;
update translations set short = 'HEEEEEEJ' where system_text = 'conveyor_belt';

-- Example of a constraint activation update
update entity_relation_constraints
set active = true
where parent_type_name = 'workcenter' and child_type_name = 'machine';

update entity_relation_constraints
set active = true
where parent_type_name = 'production_line' and child_type_name = 'production_line';

select * from entity_type;
select * from entity;

-- Check functions working
select get_uuid_entity_type_by_type_name('workcenter');
select get_uuid_entity_by_entity_name('Workcenter1');
select get_uuid_entity_type_by_entity_name('Workcenter1');

select * from entity_relation_constraints where active = true;
select * from entity_relation_constraints;

-- Example of a relation that works and one that should not work
insert into entity_relation (parent_entity, child_entity) values
(get_uuid_entity_by_entity_name('Workcenter1'), get_uuid_entity_by_entity_name('Machine1'));

insert into entity_relation (parent_entity, child_entity) values
(get_uuid_entity_by_entity_name('TactCircuit1'), get_uuid_entity_by_entity_name('ProductionLine1'));

select * from entity_relation;