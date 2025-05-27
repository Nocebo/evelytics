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