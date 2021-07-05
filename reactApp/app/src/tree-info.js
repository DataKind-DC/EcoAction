import * as React from 'react';

function TreeInfo(props) {
  const {info} = props;
  const displayName = `Trees Planted: ${info.treeCount}`;

  return (
    <div>
      {displayName}
    </div>
  );
}

export default React.memo(TreeInfo);
