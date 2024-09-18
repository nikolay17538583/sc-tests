n = NetAddr("localhost", 65313)
thisProcess.openUDPPort(n.port)


s.boot
b = Bus.control(s, 3);
c = Bus.control(s, 3)

x = { (( \l.kr(0!3) - \r.kr(0!3)) * 10).pow(2).abs.sum.sqrt |> OnePole.kr(_, 0.8) }.scope


(
x = {
	var d = \l.kr(0!3)[1] - \r.kr(0!3)[1];
	var dis = d.pow(2).abs.sqrt;
	var sl = Slope.kr(dis) > 20;

	var freq = Demand.kr(sl, 0, Dwhite(200, 400));

	var open = dis > 0.01;
	var env = Env.adsr(0.01, 0.3, 0.5, 0.1, 1.0, -4).ar(gate: open) * OnePole.kr(dis.linlin(0, 0.15, 0, 1).clip(0,1), 0.8);
	SinOsc.ar(freq)!2 * env
}.play
)

x.free

b.scope
c.scope

OSCdef(\l, {|msg|
	x.set(\l, msg[1..]);
}, '/webcam/delta/lip/bot');

OSCdef(\r, {|msg|
	x.set(\r, msg[1..]);
}, '/webcam/delta/lip/top')

OSCdef(\f).stop