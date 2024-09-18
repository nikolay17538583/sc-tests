"Starting to launch jellyfish".postln;

~hpwd = "/home/jordan/Work/projects/jellyfish"; // home working dir
~pwd = ~hpwd +/+ "sc"; // project working directory
~camwd = ~hpwd +/+ "webcamtrack_mediapipe";
~settings_file_to_load = "control_presets/default.json";

~outChans = 4; // does stereo output any way, just internal.

///////////////////////////////////
// * Define OSC ports

~to_unity =    NetAddr("localhost", 12346);
~from_unity =  NetAddr("localhost", 12347);
~from_webcam = NetAddr("localhost", 65313);

JHCheckUDPListeningPort(~from_webcam);
JHCheckUDPListeningPort(~from_unity);

///////////////////////////////////
// * Server Settings

s.options.memSize = 2.pow(20); // about 1 gb - overkill
s.options.memoryLocking = true; // necessary?
s.options.numInputBusChannels = 2;
s.options.numWireBufs = 1024;
s.options.numOutputBusChannels = 2 + 1 + ~outChans;

///////////////////////////////////
// * subtargets

~subtargets = JHSubTargets()

.add(\launch_unity, func: {
	var unity_progam = unixCmd(~hpwd +/+ "/jellyfish_unity_builds/buildK.x86_64");
	var t = 0.1.wait;
	var kill_unity = { unixCmd("kill -9" +  unity_progam); };
	ShutDown.add(kill_unity);
	ServerQuit.add(kill_unity);
})

.add(\launch_mediapipe, func: {
	var mediapipe = unixCmd(~camwd +/+ "/venv/bin/python" + ~camwd +/+ "/main.py");
	var t = 0.1.wait;
	var kill_mediapipe = {
		unixCmd("kill -9" +  mediapipe);
		unixCmd("killall -9 python");
	};
	ShutDown.add(kill_mediapipe);
	ServerQuit.add(kill_mediapipe);
})

.add(\jack_connect, func: {
	[
		"jack_connect system:capture_3 SuperCollider:in_1",
		"jack_connect system:capture_4 SuperCollider:in_2",

		"jack_connect SuperCollider:out_1 system:playback_1",
		"jack_connect SuperCollider:out_2 system:playback_2",

		// consider sending the mics out seperately?
		//"jack_connect system:capture_3 system:playback_3",
		//"jack_connect system:capture_4 system:playback_3",
	].do(_.unixCmd);
})

.add(\buildDataSets, func: {
	~waterDataSet = JHImport(~pwd +/+ "datasets/water.scd").(
		cachePath: ~pwd +/+ "audio/cache/waterDrops",
		audioFile: ~pwd +/+ "audio/waterDrops.wav"
	);
	~guitarHarmonicsDataSet = JHImport(~pwd +/+ "datasets/guitarHarmonics.scd").();
	~guitarScrapeDataSet = JHImport(~pwd +/+ "datasets/guitarScrape.scd").();
})

.add(\loadSynthDefs, func: {
	PathName(~pwd +/+ "synthDefs/mixins").files.do{ |f| f.fullPath.load };
})

.add(\defineExternalOSC, func: { JHImport(~pwd +/+ "externalOSC.scd").() })

.add(\defineRelayGroup, func: { ~relayGroup = JHGroup(Server.default, 'addToTail') })

.add(\defineIO, [\loadSynthDefs], {
	~inputGroup = JHImport(~pwd +/+ "groups/input/input_group.scd");

	~synthGroup = JHGroup();

	~outputGroup = JHGroup().withGroup {
		JHSynthDef.mkSynth('output/mixer', func: {
			SinkRd.ar('in', ~outChans) * Env([0,0,1], 2, 1).ar(0, 1)
			|> Limiter.ar(_, -1.dbamp, 0.0001)
			|> JHSynthMixin(\AnalysisMixin, _)
			|> {|l| Out.ar(0, [Splay.ar(l), Silent.ar(), l].flat) }
		})
	};
})

.add(\defineMainEffects, [\defineIO], {
	~synthGroup.withGroup {
		~effectGroup = JHGroup(addAction: 'addToTail').withGroup {
			JHImport(~pwd +/+ "groups/effect/reverb.scd").(
				outChans: ~outChans,
				ambiFile: ~pwd +/+ "audio/ir/york_minster_ambi.wav"
			)
			.connect(_.getOut('out'), ['output/mixer', 'in']);
		}
	}
})

.add(\defineMainSynths, [\defineMainEffects, \buildDataSets], {
	~synthGroup.withGroup {
		~mainGroup = JHGroup(addAction: 'addToHead').withGroup {

			JHImport(~pwd +/+ "groups/main/water_grains.scd").(
				outChans: ~outChans,
				waterDataSet: ~waterDataSet,
				numNeighbours: 4
			)
			.connect(_.getOut('out'), ['output/mixer', 'in'])
			.connect(_.getOut('out/wet'), ['effect/reverb', 'in']);

			JHImport(~pwd +/+ "groups/main/slow_water_changes.scd").(
				outChans: ~outChans,
				waterDataSet: ~waterDataSet
			)
			.connect(_.getOut('out'), ['output/mixer', 'in'])
			.connect(_.getOut('out/wet'), ['effect/reverb', 'in']);

			JHImport(~pwd +/+ "groups/main/bass_wobble.scd").(
				outChans: ~outChans
			)
			.connect(_.getOut('out'), ['output/mixer', 'in']);

			JHImport(~pwd +/+ "groups/main/guitar_playback.scd").(
				outChans: ~outChans
			)
			.connect(['in/mic', 'out/mono'], _.getIn('in/mono'))
			.connect(_.getOut('out'), ['output/mixer', 'in'])
			.connect(_.getOut('out/wet'), ['effect/reverb', 'in']);

			JHImport(~pwd +/+ "groups/main/live_echos.scd").(
				outChans: ~outChans
			)
			.connect(['in/mic', 'out/mono'], _.getIn('in/mono'))
			.connect(_.getOut('out'), ['output/mixer', 'in'])
			.connect(_.getOut('out/wet'), ['effect/reverb', 'in']);
		}
	}
})

.add(\defineOSCRelaySynth, [\defineRelayGroup, \defineExternalOSC], {
	~relayGroup.withGroup { JHOSCStore.createRelaySynth(triggerRate: 120) }
})

.add(\defineMainMap, [\defineExternalOSC, \defineMainSynths], {
	// silence - fade in
	(~pwd +/+ "maps/00.scd").load;

	// section A
	(~pwd +/+ "maps/01.scd").load;
	(~pwd +/+ "maps/02.scd").load;
	(~pwd +/+ "maps/03.scd").load;
	//
	(~pwd +/+ "maps/04.scd").load;

	// section B
	(~pwd +/+ "maps/05.scd").load;

	(~pwd +/+ "maps/06.scd").load;

	//(~pwd +/+ "maps/07.scd").load;
	(~pwd +/+ "maps/08.scd").load;
	(~pwd +/+ "maps/09.scd").load;
	(~pwd +/+ "maps/10.scd").load;
})

.add(\defineMainOSCMap, [\defineMainMap, \defineOSCRelaySynth], {
	DebugOut.enable = false;

	~relayGroup.withGroup {
		~jhoscmapper = JHOSCMapperSynth.mkSynth()
	};

	if(DebugOut.enable, {
		Routine({ loop {
			2.wait;
			postf("current position is : %\n", ~jhoscmapper.busMap['map/number'].bus.getSynchronous());
		}}).play;
	});
})


.add(\loadPreviousState, [\defineMainSynths], {
	JHSynthControls.loadFrom(~pwd +/+ ~settings_file_to_load)
})

.add(\external_launch, [\defineMainOSCMap, \loadPreviousState, \jack_connect, \launch_mediapipe], {
	~to_unity.sendMsg("/launch_project/finished", 1);
});

///////////////////////////////////
// * target launcher

~launcher = JHLauncher(~subtargets)
.addTarget('Full Piece', [\defineMainOSCMap, \loadPreviousState, \jack_connect, \launch_mediapipe, \launch_unity])
.addTarget('External Launch', [\external_launch])
//.addTarget('Full Piece - No Load', [\defineMainOSCMap])
.addTarget('Only External OSC', [\defineExternalOSC, \defineOSCRelaySynth])
.addTarget('Full Piece - No Map', [\loadPreviousState, \defineOSCRelaySynth])
//.addTarget('Synth Tester', [\synthTester])
//.addTarget('Build Data Sets', [\buildDataSets])
.addTarget('Prep For Scratch', [\defineMainSynths])
.addTarget('Data Set Tester', [\buildDataSets])
//.mkGUI()
;


OSCFunc.newMatching({ |...msg|
	~to_unity.sendMsg("/launch_project/launching", 1);
	~launcher.launchTarget('External Launch');
}, "/launch_project");






















