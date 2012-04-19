insert into mapscans (title, nypl_digital_id, description,
                      catnyp, uuid, parent_uuid, created_at, updated_at)
    select substr(get_raw(filename,'main_title',1),0,255) as title, 
           substr(filename,0,length(filename)-4) as nypl_digital_id,
           'from ' || get_raw(filename,'main_title',2) as description,
           get_raw(filename,'catnyp',1) as catnyp,
           get_raw(filename,'uuid',1) as uuid,
           get_raw(filename,'parent_uuid',2) as parent_uuid,
           now() as created_at,
           now() as updated_at
           from (select distinct filename from raw_metadata) as images;

