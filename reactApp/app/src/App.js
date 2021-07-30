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
import {MapStyles} from './MapStyles';

import mapboxgl from "mapbox-gl";
// Needed for now to address mapbox-gl bug
// eslint-disable-next-line import/no-webpack-loader-syntax
mapboxgl.workerClass = require("worker-loader!mapbox-gl/dist/mapbox-gl-csp-worker").default;

const {REACT_APP_TOKEN, REACT_APP_API_URI} = process.env

const blockGroupNames = Array.from({length: 181}, (_, i) => {
  return {bg_name: (i + 1).toString()}
})


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
  const [openPlantable, setOpenPlantable] = useState(null);
  const [plantedTrees, setPlantedTrees] = useState(null);
  const [blockGroupMeta, setBlockGroupMeta] = useState(null);
  const [blockGroupNamePlacements, setBlockGroupNamePlacements] = useState(null);

  function arlingtonBoundsViewport() {
    let width = window.innerWidth;
    let height = window.innerHeight;
    const vp = new WebMercatorViewport({
      width: width,
      height: height,
    });
    const {longitude, latitude, zoom} = vp.fitBounds(
      [[minLng, minLat], [maxLng, maxLat]],
      {padding: 10}
    );
    setViewport({
      width: width,
      height: height,
      longitude: longitude,
      latitude: latitude,
      zoom: zoom,
    })
    setCurrentBlockGroupName(null)
    setPopupInfo(null)
  }

  useEffect(() => {
    // TODO: can I do this outside an effect since I only need to do it once?
    fetch(`${REACT_APP_API_URI}/api/blockgroups`)
      .then((res) => res.json())
      .then((data) => setBlockGroupGeos(data.data))
    fetch(`${REACT_APP_API_URI}/api/blockgroupnameplacements`)
      .then((res) => res.json())
      .then((data) => setBlockGroupNamePlacements(data.data))
    fetch(`${REACT_APP_API_URI}/api/blockgroupnames`)
      .then((res) => res.json())
      .then((data) => setBlockGroupMeta(data.data))
  }, [])

  // const [zoom, setZoom] = useState(null)
  // useEffect(() => {
  //   setZoom(viewport.zoom)
  // },[viewport])

  useEffect(() => {
    if (currentBlockGroupMeta) {
      const requestOptions = {
        method: 'POST',
        headers: {'Content-Type': 'application/json'},
        body: JSON.stringify({authenticated: apiTokenValid()})
      };
      fetch(`${REACT_APP_API_URI}/api/blockgroup/${currentBlockGroupMeta.geo_id}`, requestOptions)
        .then((res) => res.json())
        .then(
          (data) => {
            setOpenPlantable(data.openPlantable.geometry)
            setPlantedTrees(data.trees)
          }
        )
    }
  }, [currentBlockGroupMeta])

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

  function onMapClick(event) {
    const feature = event.features[0];
    if (feature) {
      switch (feature.layer.id) {
        case 'block-groups-fill':
          setCurrentBlockGroupName({bg_name: feature.properties.bg_name})
          setPopupInfo(null)
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
          onClick={onMapClick}
          onLoad={arlingtonBoundsViewport}
        >
          <Source id="block-groups" type="geojson" data={blockGroupGeos}>
            <Layer {...MapStyles.blockGroupLine} />
            <Layer {...MapStyles.blockGroupFill} />
          </Source>
          <Source id="block-group-names" type="geojson" data={blockGroupNamePlacements}>
            <Layer {...MapStyles.blockGroupNames} />
          </Source>
          <Source id="open-plantable" type="geojson" data={openPlantable}>
            <Layer {...MapStyles.openPlantable} />
          </Source>
          <Source id="planted-trees" type="geojson" data={plantedTrees}>
            <Layer {...MapStyles.plantedTrees} />
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

          <GeolocateControl style={{top: 0, left: 0, padding: '4px'}}/>
          <FullscreenControl style={{top: 36, left: 0, padding: '4px'}}/>
          <NavigationControl style={{top: 72, left: 0, padding: '4px'}}/>
          <ScaleControl style={{bottom: 22, left: 0, padding: '4px'}}/>
        </MapGL>
          <Login/>
        <div className="sidebar">
          <Button variant={"contained"} color={"primary"} onClick={arlingtonBoundsViewport}> Reset Map </Button>
          <Autocomplete
            value={currentBlockGroupName}
            onChange={(event, newValue) => {
              setCurrentBlockGroupName(newValue)
            }}
            id="combo-box-demo"
            color="primary"
            options={blockGroupNames}
            getOptionLabel={(option) => option.bg_name}
            style={{width: 110, padding: 0}}
            disableClearable={false}
            getOptionSelected={(option, value) => option.bg_name === value.bg_name}
            renderInput={(params) => <TextField {...params} label="Block Group" variant="outlined"/>}
          />
          {/*<h4>{zoom}</h4>*/}
        </div>
      </div>
    </div>
  );
}

export default App;
