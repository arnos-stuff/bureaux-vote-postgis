DO
$do$
declare
    chunk int;
    old_chunk int := 0;
    fname varchar;
    chunks varchar[] := array[10000,20000, 30000, 40000, 50000, 60000, 70000];
begin
    foreach chunk in array chunks
    loop
        fname := concat('/tmp/bureaux.chunk.idx.' , old_chunk,  '.', chunk , '.geojson');
        raise notice 'exporting rows % to % => file "%"',old_chunk,chunk,fname;
        execute format('COPY (
            SELECT jsonb_build_object( ''type'', ''FeatureCollection'', ''features'', jsonb_agg(feature))
            FROM (
            SELECT jsonb_build_object(
                ''type'',       ''Feature'',
                ''id'',         insee,
                ''geometry'',   ST_AsGeoJSON(geom)::jsonb,
                ''properties'', to_jsonb(row) - ''block_ids'' - ''geom'' - ''row_id''
            ) AS feature
            FROM (
                SELECT *, ROW_NUMBER() OVER (ORDER BY insee) row_id FROM bureau_total
                ) row
                WHERE row_id < %s AND row_id >= %s
                ) feature
            ) TO %L;
            ',chunk, old_chunk, fname);
    old_chunk := chunk;
    end loop;
end
$do$