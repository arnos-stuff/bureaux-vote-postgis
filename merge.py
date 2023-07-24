import geopandas as gpd
import pandas as pd

chunks = list(range(8))
formats = [
    ["GeoJSON", "geojson"],
    ["ESRI Shapefile", "shp"],
    ["GPKG", "gpkg"]
    
]
SIZE = 10**4

data = []
for start, stop in zip(chunks, chunks[1:]):
    print(f"Loading chunk {start}/{max(chunks)-1} ..")
    data += [
        gpd.read_file(f"bureaux.chunk.idx.{SIZE*start}.{SIZE*stop}.geojson")
    ]

data = gpd.GeoDataFrame( pd.concat( data, ignore_index=True) )

for driver, fmt in formats:
    print(f"Saving with format = '.{fmt}' ...")
    data.to_file(f"bureaux.final.{fmt}", driver=driver)
