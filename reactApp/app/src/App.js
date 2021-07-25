import * as React from 'react';
import {useState, useEffect} from 'react';
import MapGL, {
  Popup,
  NavigationControl,
  FullscreenControl,
  ScaleControl,
  GeolocateControl,
  WebMercatorViewport,
  LinearInterpolator,
  Source,
  Layer
} from 'react-map-gl';
import {TextField, Button} from '@material-ui/core'
import Autocomplete from '@material-ui/lab/Autocomplete';
import bbox from '@turf/bbox';
import './App.css'
import {apiTokenValid} from './Library'
import Login from './components/Login/Login'
import TreeInfo from './tree-info';
import mapboxgl from "mapbox-gl"; // This is a dependency of react-map-gl even if you didn't explicitly install it

// Needed for now to address mapbox-gl bug
// eslint-disable-next-line import/no-webpack-loader-syntax
mapboxgl.workerClass = require("worker-loader!mapbox-gl/dist/mapbox-gl-csp-worker").default;

const blockGroupNames = Array.from({length: 181}, (_, i) => {
  return {bg_name: (i + 1).toString()}
})
const {REACT_APP_TOKEN} = process.env
const apiUrl = process.env.REACT_APP_API_URI

const geolocateStyle = {top: 0, left: 0, padding: '10px'};
const fullscreenControlStyle = {top: 36, left: 0, padding: '10px'};
const navStyle = {top: 72, left: 0, padding: '10px'};
const scaleControlStyle = {bottom: 36, left: 0, padding: '10px'};

function App() {

  const minLng = -77.17424106299076
  const maxLng = -77.02886958304389
  const minLat = 38.82511348026591
  const maxLat = 38.9360680365353
  // TODO: use bounds to do initial load
  const [viewport, setViewport] = useState({
    latitude: (minLat + maxLat) / 2,
    longitude: (minLng + maxLng) / 2,
    zoom: 10,
    bearing: 0,
    pitch: 0
  });
  const [popupInfo, setPopupInfo] = useState(null);
  const [currentBlockGroupName, setCurrentBlockGroupName] = useState(null)
  const [currentBlockGroupMeta, setCurrentBlockGroupMeta] = useState(null)
  const [blockGroupGeos, setBlockGroupGeos] = useState(null);

  // TODO: How do I get these before rendering?
  const [blockGroupNamePlacements, setBlockGroupNamePlacements] = useState(null);
  const [openPlantable, setOpenPlantable] = useState(null);
  const [plantedTrees, setPlantedTrees] = useState(null);
  const [blockGroupMeta, setBlockGroupMeta] = useState(null);

  function arlingtonBoundsViewport() {
    let width = window.innerWidth;
    let height = window.innerHeight;
    const vp = new WebMercatorViewport({
      width: width,
      height: height,
    });
    const {longitude, latitude, zoom} = vp.fitBounds(
      [[minLng, minLat], [maxLng, maxLat]],
      {padding: 30}
    );
    setViewport({
      width: width,
      height: height,
      longitude: longitude,
      latitude: latitude,
      zoom: zoom,
    })
  }

  useEffect(() => {
    // TODO: can I do this outside an effect since I only need to do it once?
    fetch(`${apiUrl}/api/blockgroups`)
      .then((res) => res.json())
      .then(
        (data) => {
          setBlockGroupGeos(data.data)
        })
    fetch(`${apiUrl}/api/blockgroupnameplacements`)
      .then((res) => res.json())
      .then(
        (data) => {
          setBlockGroupNamePlacements(data.data)
        })
    fetch(`${apiUrl}/api/blockgroupmeta`)
      .then((res) => res.json())
      .then(
        (data) => {
          setBlockGroupMeta(data.data)
        })
  }, [])

  useEffect(() => {
    if (currentBlockGroupMeta) {
      fetch(`${apiUrl}/api/blockgroup/${currentBlockGroupMeta.geo_id}`)
        .then((res) => res.json())
        .then(
          (data) => {
            setOpenPlantable(data.openPlantable.geometry)
            setPlantedTrees(data.trees)
          }
        )
    }
  }, [currentBlockGroupMeta])

  const layerStyle = {
    id: 'block-groups-line',
    type: 'line',
    paint: {
      'line-width': 1.2, // TODO: increase thickness as zoom increases
      'line-color': '#0b0d10'
    }
  }
  const bgFillStyle = {
    id: 'block-groups-fill',
    type: 'fill',
    paint: {
      'fill-color': '#000000',
      'fill-opacity': 0.05
    }
  }
  const blockGroupNamesStyle = {
    id: 'block-group-names',
    type: 'symbol',
    layout: {
      'text-field': ['get', 'bg_name'],
      // 'text-offset': [1000,1000],
      // 'text-variable-anchor': ['center', 'top', 'bottom', 'left', 'right'],
      'text-variable-anchor': ['center'],
      'text-justify': 'auto',
    }
  }
  const openPlantableStyle = {
    id: 'open-plantable',
    type: 'fill',
    paint: {
      'fill-outline-color': '#0040c8',
      'fill-color': '#0080ff', // blue color fill
      'fill-opacity': 0.3
    }
  }
  const plantedTreesStyle = {
    id: 'planted-trees',
    type: 'circle',
    paint: {
      'circle-radius': {
        'base': 1,
        'stops': [
          [12, 1.5],
          [22, 18]
        ]
      },
      'circle-color': [
        'match',
        ['get', 'treeCount'],
        1, '#2e9209',
        2, '#8aa313',
        3, '#bb791d', 4, '#bb791d', 5, '#bb791d',
        6, '#fb683b', 7, '#fb683b', 8, '#fb683b', 9, '#fb683b', 10, '#fb683b',
        /* other */ '#c92828'
      ]
    }
  }

  useEffect(() => {
    if (currentBlockGroupName && blockGroupMeta) {
      const meta = blockGroupMeta.find((bg) => bg.bg_name === currentBlockGroupName.bg_name)
      setCurrentBlockGroupMeta(meta)
    }
  }, [currentBlockGroupName])

  useEffect(() => {
    if (blockGroupGeos) {
      const bgGeo = blockGroupGeos.features.find((bg) => bg.properties.bg_name === currentBlockGroupMeta.bg_name)
      // calculate the bounding box of the feature
      const [minLng, minLat, maxLng, maxLat] = bbox(bgGeo);
      // construct a viewport instance from the current state
      const vp = new WebMercatorViewport(viewport);
      const {longitude, latitude, zoom} = vp.fitBounds(
        [[minLng, minLat], [maxLng, maxLat]],
        {padding: 20});
      setViewport({
        ...viewport,
        longitude,
        latitude,
        zoom,
        transitionInterpolator: new LinearInterpolator({
          // around: [event.offsetCenter.x, event.offsetCenter.y]
        }),
        transitionDuration: 500
      })
    }
  }, [currentBlockGroupMeta])

  function onClick(event) {
    const feature = event.features[0];
    if (feature) {
      switch (feature.layer.id) {
        case 'block-groups-fill':
          setCurrentBlockGroupName({bg_name: feature.properties.bg_name})
          break
        case 'planted-trees':
          const [lng, lat] = event.lngLat
          setPopupInfo({
            ...feature.properties,
            longitude: lng,
            latitude: lat,
          })
          break
        default:
          break
      }
    }
  }

  return (
    <div className="wrapper">
      <div className="map">
        <MapGL
          {...viewport}
          width="100%"
          height="100%"
          // mapStyle="mapbox://styles/brentmaggy/ckp9w138f35yi17t83b0xlklo"
          mapStyle="mapbox://styles/brentmaggy/ckqrgap2l3vbm17o5zf3cpwbm" // streets-simple
          interactiveLayerIds={['block-groups-fill', 'planted-trees']}
          onViewportChange={setViewport}
          mapboxApiAccessToken={REACT_APP_TOKEN}
          onClick={onClick}
          onLoad={arlingtonBoundsViewport}
        >
          <Source id="block-groups" type="geojson" data={blockGroupGeos}>
            <Layer {...layerStyle} />
            <Layer {...bgFillStyle} />
          </Source>
          <Source id="block-group-names" type="geojson" data={blockGroupNamePlacements}>
            <Layer {...blockGroupNamesStyle} />
          </Source>
          <Source id="open-plantable" type="geojson" data={openPlantable}>
            <Layer {...openPlantableStyle} />
          </Source>
          <Source id="planted-trees" type="geojson" data={plantedTrees}>
            <Layer {...plantedTreesStyle} />
          </Source>
          {popupInfo && (
            <Popup
              tipSize={5}
              anchor="bottom"
              longitude={popupInfo.longitude}
              latitude={popupInfo.latitude}
              closeOnClick={true}
              onClose={setPopupInfo}
            >
              <TreeInfo info={popupInfo}/>
            </Popup>
          )}

          <GeolocateControl style={geolocateStyle}/>
          <FullscreenControl style={fullscreenControlStyle}/>
          <NavigationControl style={navStyle}/>
          <ScaleControl style={scaleControlStyle}/>
        </MapGL>
        <div className="sidebar">
          <Login/>
          <Button variant={"contained"} color={"primary"} onClick={arlingtonBoundsViewport}> Reset Zoom </Button>
          <Autocomplete
            value={currentBlockGroupName}
            onChange={(event, newValue) => {
              setCurrentBlockGroupName(newValue)
            }}
            id="combo-box-demo"
            color="primary"
            options={blockGroupNames}
            getOptionLabel={(option) => option.bg_name}
            style={{width: 100, padding: 10}}
            disableClearable={true}
            getOptionSelected={(option, value) => option.bg_name === value.bg_name}
            renderInput={(params) => <TextField {...params} label="Block Group" variant="outlined"/>}
          />
        </div>
        {/*<ControlPanel info={currentBlockGroup}/>*/}
      </div>
    </div>
  );
}


export default App;
