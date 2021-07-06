const express = require('express')
const fs = require('fs')
const papa = require('papaparse')
// const turf = require('@turf/turf')
const polylabel = require('./polylabel')

const app = express();
const PORT = process.env.PORT || 3001;

app.use(function(req, res, next) {
  res.header("Access-Control-Allow-Origin", "*");
  res.header("Access-Control-Allow-Headers", "Origin, X-Requested-With, Content-Type, Accept");
  next();
});


let file = fs.readFileSync('./data/trees.csv').toString('utf-8');
const trees = papa.parse(file, {header: true})

file = fs.readFileSync('./data/block_group_meta.csv').toString('utf-8');
const blockGroupMeta = papa.parse(file, {header: true}).data

function blockGroupNameFromGeoId(geoId) {
  return blockGroupMeta.find((bg) => bg.geo_id === geoId).bg_name.toString()
}

function shiftPointFeaturePlacement(pointFeature, up = 0, right = 0) {
  pointFeature.geometry.coordinates[1] += up
  pointFeature.geometry.coordinates[0] += right
  return pointFeature
}


function blockGroupNamePlacement(blockGroupGeo) {
  let poly = polylabel(blockGroupGeo.geometry.coordinates)
  let geoId = blockGroupGeo.properties.geo_id;
  let bgName = blockGroupNameFromGeoId(geoId)
  // let center = turf.centerOfMass(blockGroupGeo)
  // center.properties = {geo_id: geoId, bg_name: bgName}
  let bgNamePlacement = {
    type: "Feature",
    properties: {geo_id: geoId, bg_name: bgName},
    geometry: {type: "Point", coordinates: poly.slice(0, 2)}
  }
  switch (geoId) {
    case "510131022003":
      bgNamePlacement = shiftPointFeaturePlacement(bgNamePlacement, 0.001)
      break
    case "510131034011":
      bgNamePlacement = shiftPointFeaturePlacement(bgNamePlacement, 0.003, -0.003)
      break
    case "510131028022":
      bgNamePlacement = shiftPointFeaturePlacement(bgNamePlacement, -0.0005, -0.0015)
      break
    case "510131034025":
      bgNamePlacement = shiftPointFeaturePlacement(bgNamePlacement, 0.001, -0.0015)
      break
    case "510131036022":
      bgNamePlacement = shiftPointFeaturePlacement(bgNamePlacement, 0.005,)
      break
    // case "510131035012":
    //   bgNamePlacement = shiftPointFeaturePlacement(bgNamePlacement, 0, -0.0007)
    //   break
    default:
  }

  return bgNamePlacement
}

function preprocessBlockGroups() {
  let blockGroupGeos = JSON.parse(fs.readFileSync('./data/block_groups.geojson'), 'utf8')
  blockGroupGeos.features.forEach((bg) =>  bg.properties.bg_name = blockGroupNameFromGeoId(bg.properties.geo_id))

  let placements = blockGroupGeos.features.map(blockGroupNamePlacement)
  let blockGroupNamePlacements = {type: "FeatureCollection", name: "block_group_name_placements", features: placements}
  return {blockGroupGeos, blockGroupNamePlacements}
  // return blockGroupGeos
}

const {blockGroupGeos, blockGroupNamePlacements} = preprocessBlockGroups()

function getBlockGroupData(geo_id) {
  return blockGroupGeos['features'].find((bg) => bg.properties.geo_id === geo_id)
}

function createTreePointFeature(treeObj) {
  return {
    "type": "Feature",
    "properties": {"treeCount": Number(treeObj.tree_count)},
    "geometry": {"type": "Point", "coordinates": [Number(treeObj.long), Number(treeObj.lat), 0.0]}
  }
}

function getBlockGroupTrees(geo_id) {
  let bgTrees = trees.data.filter((bg) => (bg.block_group_id === geo_id))
  let bgTreesGeoJson = []
  bgTrees.forEach((t) => {
    let latLngMatchI = bgTreesGeoJson.findIndex((geo) => {
      return (geo.geometry.coordinates.toString() === `${t.long},${t.lat},0`)
    })
    if (latLngMatchI !== -1) {
      bgTreesGeoJson[latLngMatchI].properties.treeCount += Number(t.tree_count)
    } else {
      bgTreesGeoJson.push(createTreePointFeature(t))
    }
  })
  return {
    "type": "FeatureCollection",
    "features": bgTreesGeoJson
  }
}

app.get('/api/blockgroup/:geo_id', (req, res) => {
  const boundary = getBlockGroupData(req.params.geo_id)
  const trees = getBlockGroupTrees(req.params.geo_id)
  const openPlantable = JSON.parse(fs.readFileSync(`./data/open_plantable/op_${req.params.geo_id}.geojson`), 'utf8')['features'][0]

  res.json({
    boundary: boundary,
    openPlantable: openPlantable,
    trees: trees
  })
})

app.get('/api/blockgroups', (req, res) => {
  res.json({
    data: blockGroupGeos
  })
})

app.get('/api/blockgroupnameplacements', (req, res) => {
  res.json({
    data: blockGroupNamePlacements
  })
})

app.get('/api/blockgroupmeta', (req, res) => {
  res.json({
    data: blockGroupMeta
  })
})


app.listen(PORT, () => {
  console.log(`Server listening on ${PORT}`);
});