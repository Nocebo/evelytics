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
