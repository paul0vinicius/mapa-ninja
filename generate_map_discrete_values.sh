# Transforma o shp em json para manipulação
# Passo 2: SHP -> GeoJSON
shp2json pb_setores_censitarios/25SEE250GC_SIR.shp -o pb.json

# Terra não é plana - Distorção dos mapas
# Passo 3: GeoJSON -> GeoJSON projetado
geoproject 'd3.geoOrthographic().rotate([54, 14, -2]).fitSize([1000, 600], d)' < pb.json > pb-ortho.json

# Tamanho da imagem definido
geo2svg -w 1000 -h 600 < pb-ortho.json > pb-ortho.svg

# Passo 4: GeoJSON -> NDJSON
ndjson-split 'd.features' < pb-ortho.json > pb-ortho-ndjson.ndjson

# Passo 5: NDJSON -> NDJSON + dados
dsv2json -r ';' -n < PB/base2010/CSV/Basico_PB.csv > pb-censo.ndjson

# Mapeando o codigo do setor
ndjson-map 'd.Cod_setor = d.properties.CD_GEOCODI, d' < pb-ortho-ndjson.ndjson > saida-ortho-sector.ndjson

# Fazendo o join dos babados
ndjson-join 'd.Cod_setor' saida-ortho-sector.ndjson pb-censo.ndjson > ndjson-join.ndjson

# Apenas um objeto por linha e com as variáveis que queremos
ndjson-map 'd[0].properties = {renda: Number(d[1].V005.replace(",", "."))}, d[0]' < ndjson-join.ndjson > pb-ortho-comdado.ndjson

# Passo 6: NDJSON -> TopoJSON
geo2topo -n tracts=pb-ortho-comdado.ndjson > pb-tracts-topo.json

# Simplificando a geometria do TopoJSON
toposimplify -p 1 -f < pb-tracts-topo.json | topoquantize 1e5 > pb-quantized-topo.json

# Gerando a visualização de fato
topo2geo tracts=- < pb-quantized-topo.json | ndjson-map -r d3 'd3.scaleThreshold().domain([500, 1000, 1500, 2000]).range(d3.schemeBlues[3]), d.features.forEach(f => f.properties.fill = z(f.properties.renda)), d' | ndjson-split 'd.features' | geo2svg -n --stroke none -w 1000 -h 600 > map-discrete-values.svg
