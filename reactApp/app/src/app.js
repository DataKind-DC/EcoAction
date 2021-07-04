import * as React from 'react';
import {useState, useEffect} from 'react';
import {render} from 'react-dom';
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
import bbox from '@turf/bbox';

import ControlPanel from './control-panel';
import Pins from './pins';
import CityInfo from './city-info';
import CITIES from '../cities.json';

// const {MAPBOX_TOKEN} = process.env
const MAPBOX_TOKEN = 'pk.eyJ1IjoiYnJlbnRtYWdneSIsImEiOiJja2Q2OGdjdjQwdnl5MnhvZGF5cGhhZ20zIn0.OOQgT69LrC33k4MGpJpziw' // Set your mapbox token here

const geolocateStyle = {top: 0, left: 0, padding: '10px'};
const fullscreenControlStyle = {top: 36, left: 0, padding: '10px'};
const navStyle = {top: 72, left: 0, padding: '10px'};
const scaleControlStyle = {bottom: 36, left: 0, padding: '10px'};

export default function App() {

  const minLng = -77.17424106299076
  const maxLng = -77.02886958304389
  const minLat = 38.82511348026591
  const maxLat = 38.9360680365353
  // TODO: use bounds to do initial load
  const [viewport, setViewport] = useState({
    latitude: (minLat + maxLat) / 2,
    longitude: (minLng + maxLng) / 2,
    zoom: 12,
    bearing: 0,
    pitch: 0
  });
  const [popupInfo, setPopupInfo] = useState(null);
  // const [blockGroupName, setBlockGroupName] = useState(blockGroupNames[0])
  const [currentBlockGroup, setCurrentBlockGroup] = useState(null)
  const [blockGroupGeos, setBlockGroupGeos] = useState(null);
  const [blockGroupNamePlacements, setBlockGroupNamePlacements] = useState(null);
  const [openPlantable, setOpenPlantable] = useState(null);
  const [plantedTrees, setPlantedTrees] = useState(null);
  // const [blockGroupMeta, setBlockGroupMeta] = useState(null);
  //
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
    fetch(`/api/blockgroups`)
      .then((res) => res.json())
      .then(
        (data) => {
          setBlockGroupGeos(data.data)
        })
    fetch(`/api/blockgroupnameplacements`)
      .then((res) => res.json())
      .then(
        (data) => {
          setBlockGroupNamePlacements(data.data)
        })
    // fetch(`/api/blockgroupmeta`)
    //   .then((res) => res.json())
    //   .then(
    //     (data) => {
    //       setBlockGroupMeta(data.data)
    //     })
  }, [])

  useEffect(() => {
    if (currentBlockGroup) {

      fetch(`/api/blockgroup/${currentBlockGroup.geo_id}`)
        .then((res) => res.json())
        .then(
          (data) => {
            setOpenPlantable(data.openPlantable.geometry)
            setPlantedTrees(data.trees)
          }
        )
    }
  }, [currentBlockGroup])

  const layerStyle = {
    id: 'block-groups-line',
    type: 'line',
    paint: {
      'line-width': 1,
      'line-color': '#0080ef'
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
  const onClick = event => {
    const feature = event.features[0];
    if (feature) {
      const bgName = feature.properties.bg_name
      const bgGeo = blockGroupGeos.features.find((bg) => bg.properties.bg_name === bgName)
      // calculate the bounding box of the feature
      const [minLng, minLat, maxLng, maxLat] = bbox(bgGeo);
      // construct a viewport instance from the current state
      console.log(viewport)
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
      setCurrentBlockGroup(feature.properties)
    }
  };


  return (
    <>
      <MapGL
        {...viewport}
        width="100%"
        height="100%"
        mapStyle="mapbox://styles/brentmaggy/ckp9w138f35yi17t83b0xlklo"
        // mapStyle="mapbox://styles/mapbox/light-v9"
        interactiveLayerIds={['block-groups-fill']}
        onViewportChange={setViewport}
        mapboxApiAccessToken={MAPBOX_TOKEN}
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
        <Pins data={CITIES} onClick={setPopupInfo}/>

        {popupInfo && (
          <Popup
            tipSize={5}
            anchor="top"
            longitude={popupInfo.longitude}
            latitude={popupInfo.latitude}
            closeOnClick={false}
            onClose={setPopupInfo}
          >
            <CityInfo info={popupInfo}/>
          </Popup>
        )}

        <GeolocateControl style={geolocateStyle}/>
        <FullscreenControl style={fullscreenControlStyle}/>
        <NavigationControl style={navStyle}/>
        <ScaleControl style={scaleControlStyle}/>
      </MapGL>

      <ControlPanel/>
    </>
  );
}

export function renderToDom(container) {
  render(<App/>, container);
}
