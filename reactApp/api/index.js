const express = require('express')
const fs = require('fs')
const papa = require('papaparse')
// const turf = require('@turf/turf')
const bodyParser = require('body-parser')
const cors = require('cors')
const jwt = require('jsonwebtoken')
const polylabel = require('./polylabel')
const {getBlockGroupTrees, blockGroupGeos, blockGroupNamePlacements, blockGroupMeta} = require('./library')
const JWT_SECRET = process.env.JWT_SECRET
const app = express();
const PORT = process.env.PORT || 3001;
app.use(cors({
  //FIXME: Add prod urls
  origin: ['http://localhost:3000', 'https://app-dev.d16bszzooeuewl.amplifyapp.com/']
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
  const valid = ((req.body.user === 'admin') && (req.body.password === 'pass'))
  if (!valid) {
    console.log('invalid')
    res.status(401).send({message: 'Invalid username or password'})
  } else {
    const token = jwt.sign({ sub: 'admin' }, JWT_SECRET, { expiresIn: '1m' });

    res.send({
      token: token
    });
  }
});

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