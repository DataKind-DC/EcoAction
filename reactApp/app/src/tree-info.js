import * as React from 'react';

function TreeInfo(props) {
  const {info} = props;

  return (
    <div>
      {info.address}
      <p>
        <b>{info.treeCount}</b> trees planted
      </p>
    </div>
  );
}

export default React.memo(TreeInfo);
