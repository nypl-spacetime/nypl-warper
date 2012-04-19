CREATE TABLE raw_metadata (
    filename    char(32) not null,
    level       integer not null,
    name        varchar(255) not null,
    value       text
);

CREATE FUNCTION get_raw(varchar, varchar, integer) RETURNS text as '
DECLARE
    fname ALIAS FOR $1;
    key ALIAS FOR $2;
    lvl ALIAS FOR $3;
    val TEXT;
BEGIN
    SELECT INTO val value FROM raw_metadata 
        WHERE filename=fname AND name=key AND level=lvl;
    RETURN val;
END;
' LANGUAGE plpgsql;

CREATE FUNCTION raw_from_uuid(varchar, varchar) RETURNS text as '
DECLARE
    uuid ALIAS FOR $1;
    key ALIAS FOR $2;
    val TEXT;
BEGIN
    SELECT INTO val b.value FROM raw_metadata a, raw_metadata b
        WHERE a.name = ''uuid'' AND a.value = uuid
        AND b.filename = a.filename 
        AND b.level = a.level AND b.name = key
        LIMIT 1;
    RETURN val;
END;
' LANGUAGE plpgsql;


CREATE VIEW file_metadata AS
    SELECT filename,
           get_raw(filename, 'uuid', 1) AS uuid,
           get_raw(filename, 'main_title', 1) AS main_title,
           get_raw(filename, 'catnyp', 1) AS catnyp,
           get_raw(filename, 'date_depicted', 1)::varchar AS date_depicted,
           get_raw(filename, 'date_published', 1)::varchar AS date_published,
           get_raw(filename, 'page_number', 1)::varchar AS page_number,
           get_raw(filename, 'map_scale', 1)::varchar AS map_scale,
           -- ('BOX3D('|| get_raw(filename, 'west_longitude', 1) || ' '
           --         || get_raw(filename, 'south_latitude', 1) || ','
           --         || get_raw(filename, 'east_longitude', 1) || ' '
           --         || get_raw(filename, 'north_latitude', 1) || ')')::box3d
           --         AS bbox,
           get_raw(filename, 'uuid', 2) AS layer_uuid
    FROM (SELECT DISTINCT filename FROM raw_metadata) AS filenames;


CREATE VIEW layer_tree AS
    SELECT DISTINCT value AS parent, get_raw(filename, 'uuid', 1) as child 
        FROM raw_metadata
        WHERE name = 'uuid'
        AND level >= 2 ORDER BY value;

CREATE VIEW layer_properties_view AS
    SELECT DISTINCT uuid, b.name, b.value
        FROM (SELECT DISTINCT parent AS uuid FROM layer_tree) AS uuids,
             raw_metadata a, raw_metadata b
        WHERE a.name = 'uuid' AND a.value = uuid
        AND b.filename = a.filename 
        AND b.level = a.level;

CREATE UNIQUE INDEX layers_uuid_uidx ON layers (uuid);
CREATE INDEX mapscan_layers_layer_id_idx ON mapscan_layers (layer_id);
CREATE UNIQUE INDEX mapscan_layers_ids_idx ON mapscan_layers (layer_id, mapscan_id);
CREATE UNIQUE INDEX mapscans_nypl_digital_id_uidx ON mapscans (nypl_digital_id);


