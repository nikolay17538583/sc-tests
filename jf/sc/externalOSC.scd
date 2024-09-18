{

	// src
	JHOSCStore.mkSrcExternal('/webcam/nod/state', 2, [0, 0], ~from_webcam);

	JHOSCStore.mkSrcExternal('/webcam/pos/forehead', 3, [0.5, 0.5, 0.5], ~from_webcam);

	JHOSCStore.mkSrcExternal('/Reflection/luminance', 1, 0, ~from_unity);

	//sink
	JHOSCStore.mkSinkExternal('/global/force', 3, [0.5, 0.5, 0.5], ~to_unity);

	JHOSCStore.mkSinkExternal('/Jellyfish/position', 3, [0.5, 0.5, 0.5], ~to_unity);
	JHOSCStore.mkSinkExternal('/Jellyfish/position/large', 1, 0, ~to_unity);

	JHOSCStore.mkSinkExternal('/Jellyfish/rotation', 3, [0.5, 0.5, 0.5], ~to_unity);
	JHOSCStore.mkSinkExternal('/Jellyfish/texture/velocity', 2, [0.5, 0.5], ~to_unity);
	JHOSCStore.mkSinkExternal('/Jellyfish/texture/rotate', 1, 0.5, ~to_unity);
	JHOSCStore.mkSinkExternal('/Jellyfish/texture/unique', 1, 0, ~to_unity);

	JHOSCStore.mkSinkExternal('/Jellyfish/noise/scale', 2, [0, 0], ~to_unity);
	JHOSCStore.mkSinkExternal('/Jellyfish/noise/strength', 1, 0, ~to_unity);
	JHOSCStore.mkSinkExternal('/Jellyfish/noise/timescale', 1, 0.2, ~to_unity);

	JHOSCStore.mkSinkExternal('/Jellyfish/tension', 1, 1, ~to_unity);
	JHOSCStore.mkSinkExternal('/Jellyfish/decay', 1, 0.95, ~to_unity);

	JHOSCStore.mkSinkExternal('/Jellyfish/width', 1, 0, ~to_unity);
	JHOSCStore.mkSinkExternal('/Jellyfish/shape', 1, 0.0, ~to_unity);
	JHOSCStore.mkSinkExternal('/Jellyfish/thickness', 1, 0.0, ~to_unity);


	JHOSCStore.mkSinkExternal('/Jellyfish/brightness', 1, 0.5, ~to_unity);


	JHOSCStore.mkSinkExternal('/Sun/brightness', 1, 0, ~to_unity);
	JHOSCStore.mkSinkExternal('/Sun/caustic/change', 1, 0, ~to_unity);

	JHOSCStore.mkSinkExternal('/Dust/noise', 1, 0, ~to_unity);

	JHOSCStore.mkSinkExternal('/Camera/lookAt/lerp', 1, 0, ~to_unity);
	JHOSCStore.mkSinkExternal('/Camera/force/default', 1, 0, ~to_unity);
	JHOSCStore.mkSinkExternal('/Camera/fov', 1, 50/179, ~to_unity);


	JHOSCStore.mkSinkExternal('/Distort/displacement', 1, 0, ~to_unity);
	JHOSCStore.mkSinkExternal('/Distort/blur', 1, 0, ~to_unity);
	JHOSCStore.mkSinkExternal('/Distort/force', 3, [0.5,0.5,0.5], ~to_unity);
	JHOSCStore.mkSinkExternal('/Distort/size', 1, 0, ~to_unity);

}



