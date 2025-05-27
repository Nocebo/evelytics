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
comment on column entity.text_id is 'UUID of the text from texts table, used for translations';
comment on column entity.extra_config is 'Additional configuration for the entity in JSON format, can be combined with jsonb_concat with the default_config from entity_type';
