const express = require('express')
const fs = require('fs')
const papa = require('papaparse')
// const turf = require('@turf/turf')
const bodyParser = require('body-parser')
const cors = require('cors')
const jwt = require('jsonwebtoken')
const polylabel = require('./polylabel')
const {getBlockGroupTrees, blockGroupGeos, blockGroupNamePlacements, blockGroupNames} = require('./library')
const {JWT_SECRET, EO_USER, EO_PASS} = process.env
const app = express();
const PORT = process.env.PORT || 3001;
app.use(cors({
  origin: [
    'http://localhost:3000',
    'https://app-dev.d16bszzooeuewl.amplifyapp.com',
    'https://app-prod.d16bszzooeuewl.amplifyapp.com',
    'https://dev.arlingtontrees.us',
    'https://dev.arlingtontrees.us/',
    'https://arlingtontrees.us',
    'https://arlingtontrees.us/',
    'https://www.arlingtontrees.us',
    'https://www.arlingtontrees.us/',
  ]
}))
app.use(bodyParser.urlencoded({extended: false}));
app.use(bodyParser.json());


function getBlockGroupData(geo_id) {
  return blockGroupGeos['features'].find((bg) => bg.properties.geo_id === geo_id)
}

app.get('/', (req, res) => {
  res.send('ok')
})

app.post('/login', (req, res) => {
  const valid = ((req.body.user === EO_USER) && (req.body.password === EO_PASS))
  if (!valid) {
    res.status(401).send({message: 'Invalid username or password'})
  } else {
    const token = jwt.sign({sub: 'admin'}, JWT_SECRET, {expiresIn: '730d'});
    res.send({
      token: token
    });
  }
});

app.post('/api/blockgroup/:geo_id', (req, res) => {
  const authenticated = req.body.authenticated
  const boundary = getBlockGroupData(req.params.geo_id)
  const openPlantable = JSON.parse(fs.readFileSync(`./data/open_plantable/op_${req.params.geo_id}.geojson`), 'utf8')['features'][0]
  const trees = getBlockGroupTrees(req.params.geo_id, authenticated)

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

app.get('/api/blockgroupnames', (req, res) => {
  res.json({
    data: blockGroupNames
  })
})


app.listen(PORT, () => {
  console.log(`Server listening on ${PORT}`);
});