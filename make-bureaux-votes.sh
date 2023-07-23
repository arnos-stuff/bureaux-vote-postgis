#!/bin/bash

function help() {
    if [ -z "$1" ]; then
        echo "Available commands:"
        echo "  load: Download the polling center data."
        echo "  setup: Start a PostGIS server in a Docker container."
        echo "  init: Initialize the database with polling center data."
        echo "  geos: Download and import geographic data."
        echo "  connect: Open a connection to the PostgreSQL database."
        echo "  import-map: Download and import OpenStreetMap data for France. Only after init, setup, imports."
        echo "  transform: Execute a series of SQL scripts to process and transform the data. Only after init, setup, imports."
        echo "  make-bureaux: Create geometric contours for the polling stations. Only after init, setup, imports."
        echo "  post-process: Post-process the data by executing a series of SQL scripts. Only after init, setup, imports."
        echo "  pre-install: Install necessary software including Docker and Postgres, and start the Docker service. Only after init, setup, imports."
        echo "  export: Export the results to a .csv file, and copy the file from the Docker container to the host machine. Only after init, setup, imports."
        echo ""
        echo "Order of execution (type \`all\` to execute all these commands in the specific order):"
        echo "(1) load"
        echo "(2) pre-install"
        echo "(3) setup"
        echo "(4) init"
        echo "(5) geos"
        echo "(6) transform"
        echo "(7) export"
    else
        case "$1" in
            "load")
                echo "The 'load' command downloads the polling center data and saves it as a compressed .csv file."
                ;;
            "setup")
                echo "The 'setup' command starts a PostGIS server in a Docker container. PostGIS is a PostgreSQL extension that enables spatial database features."
                ;;
            "init")
                echo "The 'init' command initializes the database by creating a table and importing the polling center data into it."
                ;;
            "geos")
                echo "The 'geos' command downloads geographic data, unzips it, and imports it into the PostgreSQL database using the 'shp2pgsql' command."
                ;;
            "connect")
                echo "The 'connect' command opens a connection to the PostgreSQL database."
                ;;
            "import-map")
                echo "The 'import-map' command downloads OpenStreetMap data for France and imports it into the database using the 'imposm' command. Only after setup and data load."
                ;;
            "transform")
                echo "The 'transform' command executes a series of SQL scripts to process and transform the data. Only after setup and data load."
                ;;
            "make-bureaux")
                echo "The 'make-bureaux' command creates geometric contours for the polling stations."
                ;;
            "post-process")
                echo "The 'post-process' command post-processes the data by executing a series of SQL scripts."
                ;;
            "pre-install")
                echo "The 'pre-install' command installs necessary software including Docker and Postgres, and starts the Docker service."
                ;;
            "export")
                echo "The 'export' command exports the results to a .csv file, and copies the file from the Docker container to the host machine."
                ;;
            *)
                echo "Unknown command: $1"
                echo "Use '$0 help' for a list of available commands."
                ;;
        esac
    fi
}


function inner_prompt {
    case "$1" in
    "load")
        # Get pattern and extension from command line arguments
        shift;
        curl "https://static.data.gouv.fr/resources/bureaux-de-vote-et-adresses-de-leurs-electeurs/20230626-140445/table-adresses-reu.csv" | gzip > table-adresses-reu.csv.gz ;
        ;;
    "setup")
        # Get pattern and extension from command line arguments
        sudo docker run --rm -P -p 127.0.0.1:5432:5432 -e POSTGRES_PASSWORD="1234" --name pg postgis/postgis > /dev/null 2>&1 &
        echo "postgres server started."
        ;;
    "init")
        # Get pattern and extension from command line arguments
        psql postgresql://postgres:1234@localhost:5432/postgres -c "CREATE TABLE dep(code_commune_ref varchar,reconstitution_code_commune varchar,id_brut_bv_reu varchar,id varchar,geo_adresse varchar,geo_type varchar,geo_score decimal,longitude float,latitude float,api_line varchar,nb_bv_commune integer,nb_adresses integer);"
        zcat table-adresses-reu.csv.gz | psql postgresql://postgres:1234@localhost:5432/postgres -c "COPY dep(code_commune_ref,reconstitution_code_commune,id_brut_bv_reu,id,geo_adresse,geo_type,geo_score,longitude,latitude,api_line,nb_bv_commune,nb_adresses) FROM STDIN WITH CSV HEADER"
        ;;
    "geos")
        wget https://www.data.gouv.fr/fr/datasets/r/0e117c06-248f-45e5-8945-0e79d9136165 -O communes-20220101-shp.zip
        unzip communes-20220101-shp.zip
        shp2pgsql communes-20220101.shp | psql postgresql://postgres:1234@localhost:5432/postgres
        ;;
    "help")
        echo -e "██████╗░██╗░░░██╗██████╗░███████╗░█████╗░██╗░░░██╗██╗░░██╗  ██████╗░███████╗  ██╗░░░██╗░█████╗░████████╗███████╗"
        echo -e "██╔══██╗██║░░░██║██╔══██╗██╔════╝██╔══██╗██║░░░██║╚██╗██╔╝  ██╔══██╗██╔════╝  ██║░░░██║██╔══██╗╚══██╔══╝██╔════╝"
        echo -e "██████╦╝██║░░░██║██████╔╝█████╗░░███████║██║░░░██║░╚███╔╝░  ██║░░██║█████╗░░  ╚██╗░██╔╝██║░░██║░░░██║░░░█████╗░░"
        echo -e "██╔══██╗██║░░░██║██╔══██╗██╔══╝░░██╔══██║██║░░░██║░██╔██╗░  ██║░░██║██╔══╝░░  ░╚████╔╝░██║░░██║░░░██║░░░██╔══╝░░"
        echo -e "██████╦╝╚██████╔╝██║░░██║███████╗██║░░██║╚██████╔╝██╔╝╚██╗  ██████╔╝███████╗  ░░╚██╔╝░░╚█████╔╝░░░██║░░░███████╗"
        echo -e "╚═════╝░░╚═════╝░╚═╝░░╚═╝╚══════╝╚═╝░░╚═╝░╚═════╝░╚═╝░░╚═╝  ╚═════╝░╚══════╝  ░░░╚═╝░░░░╚════╝░░░░╚═╝░░░╚══════╝"
        echo "Usage: $0 [command] [options]"
        shift;
        help "$@"
        ;;
    "connect")
        psql postgresql://postgres:1234@localhost:5432/postgres
        ;;
    "import-map")
        # 3.5 Go
        wget http://download.openstreetmap.fr/extracts/merge/france_metro_dom_com_nc-latest.osm.pbf
        imposm import -mapping imposm.yaml -read france_metro_dom_com_nc-latest.osm.pbf -overwritecache -write -connection postgis://postgres:1234@localhost:5432/postgres
        ;;
    "transform")
        psql postgresql://postgres:1234@localhost:5432/postgres -v ON_ERROR_STOP=1 -f 10_communes.sql
        psql postgresql://postgres:1234@localhost:5432/postgres -v ON_ERROR_STOP=1 -f 20_addresses.sql
        psql postgresql://postgres:1234@localhost:5432/postgres -v ON_ERROR_STOP=1 -f 30_blocks.sql
        psql postgresql://postgres:1234@localhost:5432/postgres -v ON_ERROR_STOP=1 -f 40_voronoi.sql
        psql postgresql://postgres:1234@localhost:5432/postgres -v ON_ERROR_STOP=1 -f 50_bureau.sql
        psql postgresql://postgres:1234@localhost:5432/postgres -v ON_ERROR_STOP=1 -f 60_block2.sql
        psql postgresql://postgres:1234@localhost:5432/postgres -v ON_ERROR_STOP=1 -f 70_fill.sql
        psql postgresql://postgres:1234@localhost:5432/postgres -v ON_ERROR_STOP=1 -f 80_clean.sql
        psql postgresql://postgres:1234@localhost:5432/postgres -v ON_ERROR_STOP=1 -f 90_total.sql
        ;;
    "make-bureaux")
        psql postgresql://postgres:1234@localhost:5432/postgres -v ON_ERROR_STOP=1 -f 50_bureau.sql
        ;;
    "post-process")
        psql postgresql://postgres:1234@localhost:5432/postgres -v ON_ERROR_STOP=1 -f 60_block2.sql
        psql postgresql://postgres:1234@localhost:5432/postgres -v ON_ERROR_STOP=1 -f 70_fill.sql
        psql postgresql://postgres:1234@localhost:5432/postgres -v ON_ERROR_STOP=1 -f 80_clean.sql
        psql postgresql://postgres:1234@localhost:5432/postgres -v ON_ERROR_STOP=1 -f 90_total.sql
        ;;
    "pre-install")
        sudo dnf install docker postgres pqsl;
        sudo yum install postgis-client.x86_64 postgis-utils.x86_64 postgis.x86_64;
        sudo dnf install gdal;
        sudo systemctl start docker;
        curl -LO "https://github.com/omniscale/imposm3/releases/download/v0.11.1/imposm-0.11.1-linux-x86-64.tar.gz" ;
        tar -xvf imposm-0.11.1-linux-x86-64.tar.gz;
        sudo mv imposm-0.11.1-linux-x86-64/* /usr/local/bin/;
        ;;
    "export")
        shift;
        # case on the second argument if it exists
        case "$1" in
        "shp")
            echo "[..] Using pgSQL to SHP (pgsql2shp) to export..."
            sudo pgsql2shp -p 5432 -h localhost -u postgres -P 1234 postgres bureau_total
            sudo pgsql2shp -p 5432 -h localhost -u postgres -P 1234 postgres bureau
            echo "✅ Using pgSQL to SHP (pgsql2shp) to export..."
            ;;
        "csv")
            echo "[..] Copying from PostGIS DB to docker container FS..."
            psql postgresql://postgres:1234@localhost:5432/postgres -c "COPY (SELECT insee, bureau, block_ids, ST_AsGeoJSON(geom) as geom FROM bureau) TO '/tmp/bureaux.raw.csv' DELIMITER ',' CSV HEADER;"
            psql postgresql://postgres:1234@localhost:5432/postgres -c "COPY (SELECT insee, bureau, block_ids, ST_AsGeoJSON(geom) as geom FROM bureau_total) TO '/tmp/bureaux.final.csv' DELIMITER ',' CSV HEADER;"
            echo "✅ Copying from PostGIS DB to docker container FS."
            echo "[..] Copying from docker container FS to host local file..."
            sudo docker cp pg:/tmp/bureaux.raw.csv .
            sudo docker cp pg:/tmp/bureaux.final.csv .
            echo "✅ Copying from docker container FS to host local file."
            ;;
        "json")
            echo "[...] Copying from PostGIS DB to docker container FS..."
            psql postgresql://postgres:1234@localhost:5432/postgres -c "COPY (SELECT json_agg(row_to_json(rows)) :: text FROM (SELECT insee, bureau, block_ids, ST_AsGeoJSON(geom) as geom FROM bureau_total) as rows) TO '/tmp/bureaux.final.json'";
            psql postgresql://postgres:1234@localhost:5432/postgres -c "COPY (SELECT json_agg(row_to_json(rows)) :: text FROM (SELECT insee, bureau, block_ids, ST_AsGeoJSON(geom) as geom FROM bureau) as rows) TO '/tmp/bureaux.raw.json';"
            echo "✅ Copying from PostGIS DB to docker container FS."
            echo "[...] Copying from docker container FS to host local file..."
            sudo docker cp pg:/tmp/bureaux.raw.json .
            sudo docker cp pg:/tmp/bureaux.final.json .
            echo "✅ Copying from docker container FS to host local file."
            ;;
        *)
            echo "WARNING: No format specified. Assuming \`json\` & \`shp\` both passed."
            echo "[..] Copying from PostGIS DB to docker container FS..."
            psql postgresql://postgres:1234@localhost:5432/postgres -c "COPY (SELECT json_agg(row_to_json(rows)) :: text FROM (SELECT insee, bureau, block_ids, ST_AsGeoJSON(geom) as geom FROM bureau_total) as rows) TO '/tmp/bureaux.final.json'";
            psql postgresql://postgres:1234@localhost:5432/postgres -c "COPY (SELECT json_agg(row_to_json(rows)) :: text FROM (SELECT insee, bureau, block_ids, ST_AsGeoJSON(geom) as geom FROM bureau) as rows) TO '/tmp/bureaux.raw.json';"
            echo "✅ Copying from PostGIS DB to docker container FS."
            echo "[..] Copying from docker container FS to host local file..."
            sudo docker cp pg:/tmp/bureaux.raw.json .
            sudo docker cp pg:/tmp/bureaux.final.json .
            echo "✅ Copying from docker container FS to host local file."

            sleep 1;
            echo "[..] Using pgSQL to SHP (pgsql2shp) to export..."
            sudo pgsql2shp -p 5432 -h localhost -u postgres -P 1234 postgres bureau_total
            sudo pgsql2shp -p 5432 -h localhost -u postgres -P 1234 postgres bureau
            echo "✅ Using pgSQL to SHP (pgsql2shp) to export..."
            ;;
        esac
        ;;
    "pack")
        shift;
        zip bureaux-vote-geom.shp.zip bureau_total.shp bureau_total.shx bureau_total.prj
        zip bureaux-raw-data.shp.zip bureau.shp bureau.shx bureau.prj
        ;;
    "clean")
        shift;
        case "$1" in
        "archives")
            rm bureaux*zip;
            ;;
        "results")
            rm bureau*;
            ;;
        "all")
            rm -f *.{csv.gz,osm.pbf,osm.pbf.1,cpg,dbf,shx,shp,csv,json,prj,pmtiles,fgb};
            rm -f communes-*;
            ;;
        *)
            rm -f *.{csv.gz,osm.pbf,osm.pbf.1,cpg,dbf,shx,shp,csv,json,prj,pmtiles,fgb};
            rm -f communes-*;
            ;;
        esac
        ;;
    *)
        echo "Unknown command: $1"
        echo "Use '$0 help' for a list of available commands."
        ;;
    esac
}

function prompt {
    if [ "$1" == "all" ];then
        shift;
        echo "Running all commands .."
        inner_prompt "load";
        inner_prompt "pre-install";
        inner_prompt "setup";
        inner_prompt "init";
        inner_prompt "geos";
        inner_prompt "transform";
        inner_prompt "export";
        exit 0
    else
        inner_prompt "$@"
    fi
}

# Call the function with all supplied command line arguments
prompt "$@"