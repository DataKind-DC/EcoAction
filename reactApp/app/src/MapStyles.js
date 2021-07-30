export const MapStyles = {
  blockGroupLine: {
    id: 'block-groups-line',
    type: 'line',
    paint: {
      'line-width': {
        'base': 1.2,
        'stops': [
          [10.5, 1.2],
          [13, 1.3],
          [14, 1.5]
        ]
      },
      'line-color': '#0b0d10'
    }
  },

  blockGroupFill: {
    id: 'block-groups-fill',
    type: 'fill',
    paint: {
      'fill-color': '#000000',
      'fill-opacity': 0.05
    }
  },

  blockGroupNames: {
    id: 'block-group-names',
    type: 'symbol',
    layout: {
      'text-field': ['get', 'bg_name'],
      // 'text-offset': [1000,1000],
      // 'text-variable-anchor': ['center', 'top', 'bottom', 'left', 'right'],
      'text-variable-anchor': ['center'],
      'text-justify': 'auto',
      'text-size': {
        'base': 5,
        'stops': [
          [10.5, 7],
          [12, 10],
          [13, 12],
          [14, 14]
        ]
      },
    }
  },

  openPlantable: {
    id: 'open-plantable',
    type: 'fill',
    paint: {
      'fill-outline-color': '#964b00',
      'fill-color': '#964b00', // blue color fill
      'fill-opacity': 0.2
    }
  },

  plantedTrees: {
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
}