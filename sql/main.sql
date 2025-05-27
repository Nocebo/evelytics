/*
 * Entity Management System
 * This script creates tables and functions to manage entities in a manufacturing system.
 * 
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
 * File includes
 ************************************/

\i entity.sql
\i entity_functions.sql

\i entity_relations.sql

\i text_translations.sql
\i text_translations_functions.sql

-- IMPROVEMENTS
-- TODO: Add clousure table on entity_relation to make reads easier. Alternatively use ltree. Alternatively function with recursive CTEs to get the full tree of entities.
-- TODO: Make sure to handle circular references in the entity_relation table.
-- TODO: Make sure to handle the case where an entity is deleted and all its relations are deleted as well.
-- TODO: Parallelism in workcenters for example. Maybe need the mermaid rework.

-- ADDITIONAL FEATURES
-- TODO: Schema
-- TODO: Text translation. DONE but need to fix the update functions. Easiest should be to just pass json back and forth.
-- TODO: Views
-- TODO: Mermaid interface for entity relations, maybe requires rebuild
-- TODO: Events
-- TODO: Durations (based on events?)
-- TODO: Gitlike rollbacks for changes, change tracking

-- QUESTIONS
-- TODO: How to handle changes with rollbacks and partitions
