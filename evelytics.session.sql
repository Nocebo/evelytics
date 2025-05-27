select * from information_schema.tables where table_schema = 'public';

drop table if exists entity_type cascade;
drop table if exists entity cascade;
-- Drop all tables in public schema
drop table if exists workcenter cascade;
drop table if exists tact_circuit cascade;
drop table if exists production_line cascade;
drop table if exists machine cascade;
drop table if exists sensor cascade;


-- Create entity_type table first
CREATE TABLE IF NOT EXISTS entity_type (
    uuidv4 UUID PRIMARY KEY DEFAULT uuid_generate_v4 (),
    entity_type_name VARCHAR(255) NOT NULL,
    description TEXT,
    default_config JSONB
);

CREATE TABLE IF NOT EXISTS entity (
    uuidv4 UUID PRIMARY KEY DEFAULT uuid_generate_v4 (),
    entity_type UUID NOT NULL REFERENCES entity_type(uuidv4),
    extra_config JSONB
);

CREATE TABLE IF NOT EXISTS workcenter(
  name VARCHAR(255) NOT NULL,
  type VARCHAR(255) DEFAULT 'workcenter'::VARCHAR(255)
) inherits (entity);

CREATE TABLE IF NOT EXISTS tact_circuit (
  name VARCHAR(255) NOT NULL,
  type VARCHAR(255) DEFAULT 'tact_circuit'::VARCHAR(255)
) inherits (entity);

CREATE TABLE IF NOT EXISTS production_line (
  name VARCHAR(255) NOT NULL,
  type VARCHAR(255) DEFAULT 'production_line'::VARCHAR(255)
) inherits (entity);

CREATE TABLE IF NOT EXISTS machine (
  name VARCHAR(255) NOT NULL,
  type VARCHAR(255) DEFAULT 'machine'::VARCHAR(255)
) inherits (entity);

CREATE TABLE IF NOT EXISTS sensor (
  name VARCHAR(255) NOT NULL,
  type VARCHAR(255) DEFAULT 'sensor'::VARCHAR(255)
) inherits (entity);


insert into entity_type (entity_type_name, description, default_config) values
('workcenter', 'A workcenter in the production line', '{"default_setting": "value"}'),
('tact_circuit', 'A tact circuit in the production line', '{"default_setting": "value"}'),
('production_line', 'A production line in the factory', '{"default_setting": "value"}'),
('machine', 'A machine in the production line', '{"default_setting": "value"}'),
('sensor', 'A sensor in the production line', '{"default_setting": "value"}');

insert into workcenter (name, entity_type) values
('Workcenter 1', (select uuidv4 from entity_type where entity_type_name = 'workcenter')),
('Workcenter 2', (select uuidv4 from entity_type where entity_type_name = 'workcenter')),
('Workcenter 3', (select uuidv4 from entity_type where entity_type_name = 'workcenter'));
insert into tact_circuit (name, entity_type) values
('Tact Circuit 1', (select uuidv4 from entity_type where entity_type_name = 'tact_circuit')),
('Tact Circuit 2', (select uuidv4 from entity_type where entity_type_name = 'tact_circuit')),
('Tact Circuit 3', (select uuidv4 from entity_type where entity_type_name = 'tact_circuit'));
insert into production_line (name) values
('Production Line 1' , (select uuidv4 from entity_type where entity_type_name = 'production_line')),
('Production Line 2' , (select uuidv4 from entity_type where entity_type_name = 'production_line')),
('Production Line 3' , (select uuidv4 from entity_type where entity_type_name = 'production_line'));
insert into machine (name) values
('Machine 1'),
('Machine 2'),
('Machine 3');
insert into sensor (name) values
('Sensor 1'),
('Sensor 2'),
('Sensor 3');

select * from entity;
select * from workcenter;