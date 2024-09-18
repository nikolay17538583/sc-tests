JHOSCMapStore.append((\min: 20, \max: 20), (\time: 1, \curve: 0), {
	|src, isActive|


	(
		'syncron/holdTime': 1,
		'syncron/waitTime': 0.4,
		'syncron/anxTime': 0.4,

		'/Jellyfish/position': [0.5, 0.15, 0.5],
		'/Jellyfish/brightness': 0.0,

		'/Camera/fov': 0.25,

		'guitar/playback/dry/amp': Line.kr(0, 1, 4),
		'guitar/playback/wet/amp': Line.kr(0, 0.35, 4),
	)
});