const fs = require('fs')
const papa = require('papaparse')
const polylabel = require('./polylabel')

let file = fs.readFileSync('./data/trees.csv').toString('utf-8');
const trees = papa.parse(file, {header: true})

file = fs.readFileSync('./data/block_group_names.csv').toString('utf-8');
const blockGroupNames = papa.parse(file, {header: true}).data

function blockGroupNameFromGeoId(geoId) {
  return blockGroupNames.find((bg) => bg.geo_id === geoId).bg_name.toString()
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
}

const {blockGroupGeos, blockGroupNamePlacements} = preprocessBlockGroups()

function createTreePointFeature(treeObj) {
  const street = treeObj.address_clean.split(',')[0]
  return {
    "type": "Feature",
    "properties": {
      "treeCount": Number(treeObj.tree_count),
      "address": street
    },
    "geometry": {"type": "Point", "coordinates": [Number(treeObj.long), Number(treeObj.lat), 0.0]}
  }
}

function getBlockGroupTrees(geo_id, authenticated) {
  let bgTreesGeoJson = []
  if (authenticated) {
    let bgTrees = trees.data.filter((bg) => (bg.block_group_id === geo_id))
    bgTreesGeoJson = bgTrees.map(createTreePointFeature)
  }
  return {
    "type": "FeatureCollection",
    "features": bgTreesGeoJson
  }
}

module.exports = {getBlockGroupTrees, blockGroupGeos, blockGroupNamePlacements, blockGroupNames};
