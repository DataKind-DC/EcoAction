import * as React from 'react';

function ControlPanel(props) {
  const {info} = props;
  const displayName = info ? `Block Group: ${info.bg_name}` : 'Click on a Block Group or Select from Dropdown'
  console.log(props)
  return (
    <div className="control-panel">
      <button>Reset</button>
      <h3>Title</h3>
      <p>{displayName}</p>
      <p>
        Data source:{' '}
        <a href="https://en.wikipedia.org/wiki/List_of_United_States_cities_by_population">
          Wikipedia
        </a>
      </p>
    </div>
  );
}

export default React.memo(ControlPanel);
