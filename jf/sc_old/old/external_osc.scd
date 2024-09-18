

JHOSCStore.mkSrcExternal('/jellyfish/brightness');
JHOSCStore.mkSrcExternal('/jellyfish/centroid', numChannels: 2);

JHOSCStore.mkSrcExternal('/camera/gestureid');



JHOSCStore.mkSinkExternal('/jellyfish/set/width', netAddr: ~to_unity);
