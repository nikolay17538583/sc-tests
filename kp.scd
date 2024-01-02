(
p = Ppoisson(4,inf).asStream;
f = {
	var n = 7;
	var ratio = [9/8, 5/4, 4/3, 15/8];
	var base = ratio*100;
	var beater, sig, trig;
	beater = PinkNoise.ar(0.05)*Env.perc(0,0.01).kr;
	sig = Klank.ar(`[
		Array.geom(n, base.choose, ratio.choose),
		Array.exprand(n, 0.2, 0.3),
		Array.exprand(n, 0.1, 7.0)
	],beater);
	trig = 1 - DetectSilence.ar(sig, -60.dbamp);
	sig = Pan2.ar(sig, 1.0.rand2, Env.cutoff.ar(2, trig));
};
{
	loop {
		var n = p.next.postln;
		var time = 3;
		var wait = Array.exprand(n,0.02,1).normalizeSum*time;
		(n == 0).if({ time.wait });
		n.do { |i|
			f.play;
			wait[i].wait;
		};
	}
}.fork;
)
