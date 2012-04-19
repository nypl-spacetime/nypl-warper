\echo extracting unique raw metadata

UPDATE raw_metadata SET
    filename=btrim(filename), name=btrim(name), value=btrim(value);
CREATE TEMPORARY TABLE raw_metadata2 AS SELECT DISTINCT * FROM raw_metadata;
DELETE FROM raw_metadata;
INSERT INTO raw_metadata SELECT * FROM raw_metadata2;
DROP TABLE raw_metadata2;

\echo setting all mapscan uuids

UPDATE mapscans SET uuid=get_raw(nypl_digital_id||'u.tif', 'uuid', 1),
                    catnyp=get_raw(nypl_digital_id||'u.tif', 'catnyp', 1)
        WHERE uuid IS NULL OR uuid = '';

\echo importing new mapscans

INSERT INTO mapscans (title, nypl_digital_id, description,
                      catnyp, uuid, parent_uuid, created_at, updated_at)
    SELECT substr(btrim(get_raw(filename, 'main_title', 1)), 0, 255), 
           substr(filename,0,length(filename)-4) as nypl_digital_id,
           'from ' || get_raw(filename,'main_title',2) as description,
           get_raw(filename,'catnyp',1) as catnyp,
           get_raw(filename,'uuid',1) as uuid,
           '',
           now(),
           now()
           FROM (SELECT DISTINCT r.filename 
                FROM raw_metadata r LEFT JOIN mapscans m
                ON (substr(r.filename,0,length(r.filename)-4)
                    = m.nypl_digital_id)
                WHERE nypl_digital_id IS NULL) AS images;

\echo importing new layers

INSERT INTO layers
    SELECT nextval('layers_id_seq') AS id,
           substr(raw_from_uuid(uuid, 'main_title'),1,255) AS name,
           '' AS description,
           raw_from_uuid(uuid, 'catnyp') AS catnyp,
           uuid,
           '' as parent_uuid,
           't' AS is_visible,
           raw_from_uuid(uuid, 'date_depicted')::timestamp AS depicts_year,
           now() AS created_at,
           now() AS updated_at
    FROM (SELECT DISTINCT parent AS uuid
          FROM layer_tree lt LEFT JOIN layers l
          ON (lt.parent = l.uuid) 
          WHERE l.uuid IS NULL) AS uuids;

\echo importing mapscan_layers

INSERT INTO mapscan_layers
    SELECT nextval('mapscan_layers_id_seq') AS id,
           mapscans.id AS mapscan_id,
           layers.id AS layer_id
    FROM layer_tree, mapscans, layers
    WHERE mapscans.uuid = child AND layers.uuid = parent
    AND mapscans.id NOT IN (
        SELECT mapscan_id FROM mapscan_layers WHERE layer_id = layers.id);

\echo adding layers for orphaned maps

INSERT INTO layers
    SELECT nextval('layers_id_seq') AS id,
        title, description, catnyp, uuid, '', 't',
        raw_from_uuid(uuid, 'date_depicted')::timestamp AS depicts_year,
        now() AS created_at,
        now() AS updated_at
    FROM (SELECT mapscans.* FROM mapscans
          LEFT JOIN mapscan_layers ON (mapscans.id=mapscan_id)
          WHERE mapscan_id is null) AS orphans;

INSERT INTO mapscan_layers
    SELECT nextval('mapscan_layers_id_seq') AS id,
           mapscans.id AS mapscan_id,
           layers.id AS layer_id
    FROM mapscans, layers
    WHERE mapscans.uuid = layers.uuid
    AND mapscans.id NOT IN (
        SELECT mapscan_id FROM mapscan_layers WHERE layer_id = layers.id);

\echo updating per-layer mapscan counts

UPDATE layers SET mapscans_count=(
    SELECT COUNT(*) FROM mapscan_layers WHERE layer_id=layers.id);

\echo importing layer_properties

INSERT INTO layer_properties
    SELECT nextval('layer_properties_id_seq') AS id,
        l.id AS layer_id, props.name, props.value, 0
    FROM layer_properties_view props, layers l
    LEFT JOIN layer_properties lp ON (lp.layer_id = l.id)
    WHERE l.uuid = props.uuid AND lp.layer_id IS NULL;
