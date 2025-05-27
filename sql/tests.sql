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
update translations set short = 'Updated' where system_text = 'conveyor_belt';
select * from translations where short = 'Updated';
select get_translation_by_system_text('conveyor_belt', 'en', 'short');
select get_translation_by_system_text('conveyor_belt', 'en', 'all');

select update_translation_by_system_text(
    'conveyor_belt',
    'sv',
    'medium',
    'Bandtransportör' -- Swedish translation for 'conveyor belt'
); -- does not work
select get_translation_by_system_text('conveyor_belt', 'sv', 'medium');


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