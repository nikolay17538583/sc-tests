~waterDataSet.return(\plotFunc).(\grid)
s.plotTree

JHOSCMapperSynth.free


JHOSCStore.getSinks
.select(_.isKindOf(JHOSCSinkExternal))
.collect(_.bus)
.collect({|b| b.getnSynchronous(b.numChannels) })
.keysValuesDo({|k,v|
	var ar = (v.size == 1).if({v[0]}, {v}).round(0.01);
	(("'"++k++"': ") ++ ar).asString.postln
})


bl = [ 0.8259587020649, 0.52045606975184 ]
br = [ 0.94247787610619, 0.45338698859826 ]
tl = [ 0.88790560471976, 0.60898725687458 ]
tr = [ 1, 0.53856472166331 ]



var lows = [
	[ 0.66961651917404, 0.17907444668008 ],
	[ 0.83038348082596, 0.26827632461435 ],
	[ 0.93362831858407, 0.52448021462106 ],
	[ 0.90486725663717, 0.91348088531187 ],
	[ 0.71902654867257, 0.94567404426559 ],
	[ 0.82005899705015, 0.013413816230718 ]
];
var highs = [
	[ 0.6216814159292, 0.74245472837022 ],
	[ 0.60176991150442, 0.68879946344735 ],
	[ 0.3834808259587, 0.90878604963112 ]
];


(
//fabric
[ '/Camera/force/default', [ 0.0 ] ]
[ '/Distort/size', [ 0.0 ] ]
[ '/Jellyfish/position/large', [ 0.0 ] ]
[ '/Sun/caustic/change', [ 0.0 ] ]
[ '/Dust/noise', [ 0.0 ] ]
[ '/Jellyfish/thickness', [ 1.0 ] ]
[ '/Jellyfish/noise/timescale', [ 0.13519470393658 ] ]
[ '/Jellyfish/texture/velocity', [ 0.22483468055725, 0.085966199636459 ] ]
[ '/Jellyfish/rotation', [ 0.31300514936447, 0.48346802592278, 0.12417340278625 ] ]
[ '/Jellyfish/noise/strength', [ 0.0 ] ]
[ '/Jellyfish/width', [ 1.0 ] ]
[ '/Jellyfish/noise/scale', [ 0.34313005208969, 0.47612050175667 ] ]
[ '/Jellyfish/position', [ 0.1638501137495, 0.47244673967361, 0.32696548104286 ] ]
[ '/Jellyfish/pid', [ 1.0, 1.0, 1.0 ] ]
[ '/global/force', [ 0.49963262677193, 0.49963262677193, 1.0 ] ]
[ '/Sun/brightness', [ 0.87362235784531 ] ]
[ '/Distort/blur', [ 0.21969141066074 ] ]
[ '/Distort/force', [ 0.50110214948654, 0.51506245136261, 0.5 ] ]
[ '/Jellyfish/tint', [ 1.0 ] ]
[ '/Camera/fov', [ 0.07421013712883 ] ]
[ '/Jellyfish/tension', [ 1.0 ] ]
[ '/Jellyfish/brightness', [ 0.21381337940693 ] ]
[ '/Jellyfish/decay', [ 0.95073473453522 ] ]
[ '/Distort/displacement', [ 0.52387952804565 ] ]
[ '/Camera/lookAt/lerp', [ 0.0 ] ]
[ '/Jellyfish/shape', [ 0.0 ] ]
)

(
//flat fabric
[ '/Camera/force/default', [ 0.0 ] ]
[ '/Distort/size', [ 0.0 ] ]
[ '/Jellyfish/position/large', [ 0.0 ] ]
[ '/Sun/caustic/change', [ 0.0 ] ]
[ '/Dust/noise', [ 0.0 ] ]
[ '/Jellyfish/thickness', [ 0.28571429848671 ] ]
[ '/Jellyfish/noise/timescale', [ 0.13519470393658 ] ]
[ '/Jellyfish/texture/velocity', [ 0.0, 0.051339287310839 ] ]
[ '/Jellyfish/rotation', [ 0.4988839328289, 0.5234375, 0.22098214924335 ] ]
[ '/Jellyfish/noise/strength', [ 0.0 ] ]
[ '/Jellyfish/width', [ 0.071428574621677 ] ]
[ '/Jellyfish/noise/scale', [ 0.34313005208969, 0.47612050175667 ] ]
[ '/Jellyfish/position', [ 0.3359375, 0.50111609697342, 0.36160713434219 ] ]
[ '/Jellyfish/pid', [ 1.0, 1.0, 1.0 ] ]
[ '/global/force', [ 0.49963262677193, 0.49963262677193, 0.54352676868439 ] ]
[ '/Sun/brightness', [ 0.0 ] ]
[ '/Distort/blur', [ 0.21969141066074 ] ]
[ '/Distort/force', [ 0.50110214948654, 0.51506245136261, 0.5 ] ]
[ '/Jellyfish/tint', [ 0.61941963434219 ] ]
[ '/Camera/fov', [ 0.07421013712883 ] ]
[ '/Jellyfish/tension', [ 1.0 ] ]
[ '/Jellyfish/brightness', [ 0.21381337940693 ] ]
[ '/Jellyfish/decay', [ 0.95073473453522 ] ]
[ '/Distort/displacement', [ 0.52387952804565 ] ]
[ '/Camera/lookAt/lerp', [ 0.0 ] ]
[ '/Jellyfish/shape', [ 0.9765625 ] ]
)

(
//whirlpool
[ '/Camera/force/default', [ 0.0 ] ]
[ '/Distort/size', [ 0.091517858207226 ] ]
[ '/Jellyfish/position/large', [ 0.0 ] ]
[ '/Sun/caustic/change', [ 0.0 ] ]
[ '/Dust/noise', [ 0.0 ] ]
[ '/Jellyfish/thickness', [ 1.0 ] ]
[ '/Jellyfish/noise/timescale', [ 0.4542410671711 ] ]
[ '/Jellyfish/texture/velocity', [ 0.034598212689161, 0.25223213434219 ] ]
[ '/Jellyfish/rotation', [ 0.53794640302658, 0.49441963434219, 0.25446429848671 ] ]
[ '/Jellyfish/noise/strength', [ 0.0 ] ]
[ '/Jellyfish/width', [ 1.0 ] ]
[ '/Jellyfish/noise/scale', [ 0.74888390302658, 0.20089285075665 ] ]
[ '/Jellyfish/position', [ 0.032366070896387, 0.49441963434219, 0.49776786565781 ] ]
[ '/Jellyfish/pid', [ 1.0, 0.99888390302658, 1.0 ] ]
[ '/global/force', [ 1.0, 0.5234375, 0.50446426868439 ] ]
[ '/Sun/brightness', [ 0.0 ] ]
[ '/Distort/blur', [ 0.0 ] ]
[ '/Distort/force', [ 0.99330359697342, 0.484375, 0.5 ] ]
[ '/Jellyfish/tint', [ 1.0 ] ]
[ '/Camera/fov', [ 0.31584820151329 ] ]
[ '/Jellyfish/tension', [ 1.0 ] ]
[ '/Jellyfish/brightness', [ 0.11286681890488 ] ]
[ '/Jellyfish/decay', [ 0.94308036565781 ] ]
[ '/Distort/displacement', [ 1.0 ] ]
[ '/Camera/lookAt/lerp', [ 0.0 ] ]
[ '/Jellyfish/shape', [ 0.0 ] ]
)










~hpwd = "/home/jordan/Work/projects/jellyfish"; // home working dir
~pwd = ~hpwd +/+ "sc"; // project working directory
(


s.waitForBoot{
	var numNeighbours = 1;
	var kdTree = FluidKDTree(s, numNeighbours);
	var inbuf = Buffer.alloc(s, 2);
	var t = kdTree.fit(~waterDataSet.return(\grid));
	var t2 = Server.default.sync;

	JHGroup(target: s).withGroup{

		var in = JHSynthDef.mkSynth(oscid:'wg/in', func: {
			var loc = Line.kr([0.3,0.3], [0.4,0.8], 60);
			FluidKrToBuf.kr(loc, inbuf);
			SendReply.kr(Impulse.kr(50), '/wg/relay/result', loc);
		});

		var out = JHSynthDef.mkSynth(oscid: 'wg/snd', func: {
			var audio = ~waterDataSet.return(\audioBuffer);
			var slices = ~waterDataSet.return(\sliceBuffer);
			var getFrame = BufRd.ar(1, slices, _, interpolation: 1);

			var numNewGrain = 8;
			var newGrainTimeMax = 30;
			var newGrainTime = 30;
			var newGrainFreq = newGrainTime.reciprocal;

			var newGrain = Impulse.ar(newGrainFreq!numNewGrain)
			|> DelayN.ar(_, newGrainTimeMax, numNewGrain.collect(_ / (numNewGrain)) * newGrainTime);

			var grainEnv = Env([0, 1, 0], newGrainTime / 2, 2, 2).kr(
				gate: Trig.ar(newGrain, newGrainTime * 0.99)
			).poll(1);

			var n = LFDNoise3.kr(0.01).range(0, BufFrames.ir(slices));
			var index = Demand.ar(newGrain, 0, n).round(1);

			var startFrame = getFrame.(index);
			var endFrame = getFrame.(index + 1);
			var duration = (endFrame - startFrame) * ( BufDur.ir(audio) / BufFrames.ir(audio) );
			var overlap = 10;
			var imp = duration.reciprocal.clip(0.001, inf);

			var snd = GrainBuf.ar(1,
				trigger: Dust.ar(imp * overlap),
				dur: duration,
				sndbuf: audio,
				rate: [[2.5, 1, 0.5, 0.25]],
				pos: startFrame / BufFrames.ir(audio),
				mul:grainEnv
			).collect( _.sum );

			var line = LineSpreader.ar(4, snd)
			|> Line2Point.ar(_, MouseX.kr(-1,1), MouseY.kr(0,1));

			Out.ar(0, Splay.ar(line).tanh);
		});

		OSCdef('relay', {
			|msg|
			kdTree.kNearest(inbuf, numNeighbours, { |i|
				//out.node.set(\index, i.collect{|n| n.asInteger })
				out.node.set(\index, i.asInteger);
			});
		}, '/wg/relay/result', s.addr);

	}
}

)
~waterDataSet.return(\getClusters).()



~waterDataSet.return(\plotFunc).(\mappedDataSet)






JHSynthStore.find('guitar/playback').free



JHActiveGroup.get
















































