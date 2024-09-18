s.boot;
s.scope;

x.free;

(

SynthDef(\live, {
    //var nal =  PlayBuf.ar(1, \buf.ir(), loop: 1);
    var nal = SoundIn.ar(0);
    Out.ar(\bus.ir(), nal);
    Out.ar(0, (nal!2 * 10.dbamp).tanh * \amp.kr(0) );
}).add;

SynthDef(\live_granulator, {
    var input = \input.ar();
    var bufA = \bufA.kr();
    var bufB = \bufB.kr();

    var frames = BufFrames.kr(bufA);
    var secs2samps = { |s| s * SampleRate.ir() };
    var secs2per = { |s| s / BufDur.kr(bufA) };

    var pos = {
        var raw = LFDNoise3.ar( LFDNoise3.kr(LFDNoise3.kr(0.04).range(0.1,0.5)).range(0.2,4)!3 + LFDNoise3.kr(0.1).range(0.01, 0.2)).range(0, 1);
        var jitterFactor =  LFDNoise3.kr(0.02).range(secs2per.(0.01), secs2per.(0.1));
        var jitter = PinkNoise.ar().range(jitterFactor.neg, jitterFactor);
        (raw + jitter).clip(0, 1);
    }.();

    var write = {
        var phase = Phasor.ar(0, BufRateScale.kr(bufA), 0, frames);
        var distance = {
            var window_sz = secs2samps.(0.25);
            var frame_count = (phase - ([pos].flat * frames)).abs;
            1 - Fold.ar(frame_count, 0, frames/2).linlin(0, window_sz, 0, 1).pow(2);
        }.();
        var origRd = BufRd.ar(1, bufA, phase);

        var overdub= LFDNoise3.kr(0.05).range(-100,100).tanh.linlin(-1,1,0,1);

        var origWrite = BufWr.ar(input.blend(origRd, overdub), bufA, phase);
        var lerp = LPF.ar(ArrayMax.ar(distance)[0].linlin(0, 1, -1, 1), 10).clip(-1,1);
        var to_write = XFade2.ar(BufRd.ar(1, bufA, phase), BufRd.ar(1, bufB, phase), lerp);

        BufWr.ar(to_write, bufB, phase);
    }.();


    var freq = LFNoise2.ar(0.1).range(30, 200);
    var overlap = LFNoise2.ar(0.1).range(0.5, 4);
    var dur = freq.reciprocal * overlap;

    var grain = GrainBuf.ar(numChannels: 1,
        trigger: Impulse.ar(freq),
        dur: dur,
        sndbuf: bufB,
        rate: 1,
        pos: pos,
        interp: 2,
        maxGrains: 1024
    );

    var maxi = (Splay.ar(grain.flat) * 20.dbamp).tanh;

    Out.ar(0, maxi * \amp.kr(1));
}).add;

);




~liveBuf = Buffer.read(s, "../audio/03-220619_1748.wav");
~liveBus = Bus.audio(s, 1);
~liveSynth = Synth.head(s, \live, [\bus, ~liveBus, \buf, ~liveBuf]);

~liveSynth.free;

~liveSynth.set(\amp, 2.0)

~liveBuf.plot;


~granBufA = Buffer.alloc(s, s.sampleRate * 2);
~granBufB = Buffer.alloc(s, s.sampleRate * 2);

~granBufA.zero; ~granBufB.zero;


~gran = Synth.after(~liveSynth, \live_granulator, [\bufA, ~granBufA, \bufB, ~granBufB] );
~gran.free;
~gran.map(\input, ~liveBus);
~gran.set(\amp, 1.0);

s.freeAll;

s.plotTree;
s.scope;


