(
//Server.killAll;

~action_chain = {|...specs|
    specs.injectr( {"done chain".postln}, {
        |next_action_function, next| {
            |fts|
            var k = (server: s) ++ (action: next_action_function) ++ next;
            k[\source].postln;
            if(next_action_function == specs[0], {
                next[\act].performKeyValuePairs(next[\func], k).wait
            }, {
                next[\act].performKeyValuePairs(next[\func], k)
            });
        }}
    ).value();
};

~slice_audio_internal = {
    |audio, slices, num_threads|

    var dataSet = FluidDataSet.new(s);
    var spectral_mean_per_slice_lambda = {
        |start, end, index|
        var result = Buffer.alloc(s, 2);

        var spectral_shape = Buffer.new(s);

        var centroid = Buffer(s);
        var centroid_stats = Buffer(s);
        var centroid_mean = Buffer(s);

        var spread = Buffer(s);
        var spread_stats = Buffer(s);
        var spread_mean = Buffer(s);

        s.sync;

        FluidBufSpectralShape.processBlocking(source: audio, startFrame: start, numFrames: end - start, features: spectral_shape);

        FluidBufSelect.processBlocking(source: spectral_shape, destination: centroid, channels: [0]);
        FluidBufStats.processBlocking(source: centroid, stats: centroid_stats);
        s.sync;
        FluidBufSelect.processBlocking(source: centroid_stats, destination: centroid_mean, indices: [(centroid_stats.numFrames / 2).floor], channels: [0]); //mean

        FluidBufSelect.processBlocking(source: spectral_shape, destination: spread, channels: [3]);
        FluidBufStats.processBlocking(source: spread, stats: spread_stats);
        s.sync;
        FluidBufSelect.processBlocking(source: spread_stats, destination: spread_mean, indices: [(spread_stats.numFrames / 2).floor], channels: [0]);

        FluidBufCompose.processBlocking(source: centroid_mean, destination: result, numFrames: 1, destStartFrame: 0);
        FluidBufCompose.processBlocking(source: spread_mean, destination: result, numFrames: 1, destStartFrame: 1);


        s.sync;
        dataSet.addPoint(index, result);
        s.sync;

        result.free;
        spectral_shape.free;
        centroid.free;
        centroid_stats.free;
        centroid_mean.free;
        spread.free;
        spread_stats.free;
        spread_mean.free;
    };

    var t_1 = slices.loadToFloatArray(action: {
        |slices_array|
        var start_time = Main.elapsedTime;
        var safe_slices_array = slices_array;

        var average_sz = floor(safe_slices_array.size / num_threads);
        var remained = safe_slices_array.size - (average_sz*num_threads);
        var group_sizes = average_sz!(num_threads) + (0!(num_threads - 1) ++ [remained]);

        var indexes = group_sizes.inject([0], {|o, n| o ++ (o[o.size - 1] + n)});
        var index_pairs = [indexes[0..(num_threads - 1)], indexes[1..num_threads]].flop;

        var funcs = index_pairs.collect{ |p,i| {
            var r = ((p[0])..(p[1]));
            postf("starting slice from % to % on thread %\n", p[0], p[1], i);
            r.doAdjacentPairs{
                |start, end, index|
                if(index % 128 == 0, {
                    postf("...slicing from % to % on thread %\n", safe_slices_array[start], safe_slices_array[end], i)
                });
                if(safe_slices_array[start].isNil.not && safe_slices_array[end].isNil.not,{
                    spectral_mean_per_slice_lambda.(
                        safe_slices_array[start],
                        safe_slices_array[end],
                        start
                    )
                });
            };
            postf("thread % finished\n", i);
        } };
        s.sync;
        funcs.fork();
        s.sync;
        dataSet.size(action: { |sz|
            postf("\n\nUsing % threads, it took % seconds for % slices\n\n", num_threads, Main.elapsedTime - start_time, sz);
        });
    });

    var norm_data_set = {
        var normaliser = FluidNormalize(s);
        var standardiser = FluidStandardize(s);
        var normaliser2 = FluidNormalize(s);
        var normed = FluidDataSet(s);
        var std = FluidDataSet(s);
        var out = FluidDataSet(s);
        s.sync;
        "Begin normalising data".postln;
        normaliser.fitTransform(dataSet, normed);
        s.sync;
        standardiser.fitTransform(normed, std);
        s.sync;
        normaliser2.fitTransform(std, out);
        s.sync;
        "Finished normalising data".postln;
        out ;
    }.();
    s.sync;
    norm_data_set;
};

~slice_audio = { |audio_path, num_threads, thresh=0.0, forceReload=false|
    var logger = {
        postf("\naudio_path: %, num_threads: %, thresh: %\n\n", audio_path, num_threads, thresh);
    }.();

    var au_path = PathName(audio_path);

    var slice_path = au_path.pathOnly +/+ au_path.fileNameWithoutExtension ++ "_slices.aiff";
    var slice_exists = if(forceReload, false, PathName(slice_path).isFile);

    var dataSet_path = au_path.pathOnly +/+ au_path.fileNameWithoutExtension ++ "_dataSet.aiff";
    var dataSet_exists = if(forceReload, false, PathName(dataSet_path).isFile);

    var dataLabel_path = au_path.pathOnly +/+ au_path.fileNameWithoutExtension ++ "_dataSetLabels.json";


    var audio = {
        var b = Buffer.readChannel(s, audio_path, channels:[0]);
        s.sync;
        "loaded audio".postln;
        b;
    }.();

    var slices = if(slice_exists, {
        var b = Buffer.read(s, slice_path);
        s.sync;
        "loaded slices from file".postln;
        b
    }, {
        var b = Buffer.new(s);
        s.sync;
        FluidBufNoveltySlice.process(s, audio, indices: b, threshold: thresh, freeWhenDone: true, minSliceLength: 10).wait;
        s.sync;
        b.write(slice_path, "aiff", "float");
        s.sync;
        "genetated slices".postln;
        b
    });

    var norm_data_set = if(dataSet_exists, {
        var d_buf = Buffer.read(s, dataSet_path);
        var d = FluidDataSet(s);
        var label_set = FluidLabelSet(s);

        var dic = File.readAllString(dataLabel_path).interpret;

        dic.postln;
        dic["data"].postln;
        dic["data"].keysValuesDo{
            |k, v|
            label_set.addLabel(k, v[0]);
        };
        s.sync;

        d.fromBuffer(d_buf, 0, label_set);

        s.sync;
        d_buf.free;
        label_set.free;

        "\n\nloading norm_data_set_from file\n\n".postln;

        d;
    }, {
        var d /*FluidDataSet*/ = ~slice_audio_internal.(audio, slices,  num_threads);
        var label = FluidLabelSet(s);
        var d_buf = Buffer(s);
        var dic;

        "\n\ngenerating norm data set...\n\n".postln;

        "write to buffer".postln;
        d.toBuffer(d_buf, 0, label);
        s.sync;

        "to dict".postln;
        label.dump({|d| dic = d; });

        s.sync;

        "printing dic".postln;
        dic.postln;


        "writing dataset buffered".postln;
        d_buf.write(dataSet_path, "aiff", "float");

        s.sync;
        File.use(dataLabel_path, "w", {|f| f.write(dic.asCompileString) });
        s.sync;
        d_buf.free;
        label.free;
        d;
    });

    "Done slicing audio".postln;

    (\audio: audio, \slices: slices, \dataSet: norm_data_set);
};

~mk_kd_tree = {
    |dataSet, num_neighbours=1|
    var t = FluidKDTree(s, if(num_neighbours < 1, 1, num_neighbours));
    s.sync;
    t.fit(dataSet);
    s.sync;
    t;
};

~debug_kd_tree = {
    |kd_tree, dataSet, audio, slices, xmin=(-1), xmax=1, ymin=(-1), ymax=1|
    var i = if(~debug_kd_tree____counter.isNil, {~debug_kd_tree____counter = 0}, {
        ~debug_kd_tree____counter = ~debug_kd_tree____counter + 1;
    });
    var out = (\synthName: ("grain_" + i.asString).asSymbol );

    SynthDef(out.synthName, {
        var choice = WhiteNoise.ar(1!5).range( 0, (kd_tree.numNeighbours - 1) * \range.kr(1).clip(0,1) ).round(1);
        var new_index = Select.ar(choice, \index.ar(0!kd_tree.numNeighbours));

        var start_frame = BufRd.ar(1, slices, new_index, loop:1, interpolation:1);
        var end_frame = BufRd.ar(1, slices,  new_index + 1, loop:1, interpolation:1);
        //
        var number_of_frames = end_frame - start_frame;
        var dur_of_frame = BufDur.kr(audio) / BufFrames.kr(audio);
        var duration = number_of_frames * dur_of_frame;
        //
        var signal = GrainBuf.ar(1,
            Dust.ar(duration.reciprocal * \overlap.kr(1,0, true)),
            duration * \durScale.kr(1, 0, true),
            audio,
            1.0,
            start_frame / BufFrames.kr(audio),
        );
        Out.ar(0, Splay.ar(signal));
    }).add;


    out.input_buffer = Buffer.alloc(s, 2);
    s.sync;
    dataSet.dump({|d|
        out.data_as_dic = d;
    });
    out.launch_synth = {
        |self|
        self.synth_d = Synth(self.synthName);
    };

    s.sync;

    out.mk_plotter = {
        |self, target_synth|
        self.plotter = FluidPlotter(
            bounds: Rect(200,200,800,800),
            dict: self.data_as_dic,
            xmin: xmin, xmax: xmax,
            ymin: ymin, ymax: ymax,
            mouseMoveAction: {
                |view, x, y, modifiers|
                "begin mouseMoveAction".postln;
                out.input_buffer.loadCollection(
                    [x,y],
                    action: {
                        [x,y].postln;
                        kd_tree.kNearest(out.input_buffer, 1, { |a|
                            postf("a = % \n", a);
                            target_synth.set(\index, a.asInteger);

                            view.highlight_( a.asString );
                            if(self.debug_last_drawn.isNil.not, {
                                view.pointColor_(self.debug_last_drawn, Color.black);
                                view.pointSize_(self.debug_last_drawn, 1.0);
                            });

                            view.pointColor_(a.asString, Color.red);
                            view.pointSize_(a.asString, 5.0);
                            self.debug_last_drawn = a.asString;
                        })
                    }
                )
            }
        )
        .pointSizeScale_(0.2);
    };

    out.free_please = {
        |self|
        self.synth_d.free;
        self.plotter.close;
        self.input_buffer.free;
    };

    out;
};

s.options.memSize = 8192 * 32;
s.options.numBuffers = 1024 * 1024;
s.options.numWireBufs = 256;
s.options.maxNodes = 1024 * 32;

s.waitForBoot({
    s.sync;
    "\n\nSERVER BOOTED\n\n".warn;
    ~water_slices = ~slice_audio.(
        audio_path: "/home/jordan/Work/projects/jellyfish/sc/audio/water_foil_downloadedWater.wav",
        num_threads: 6,
        forceReload: true,
        thresh: 0.20
    );
    s.sync;
    ~water_slices.kd_tree = ~mk_kd_tree.(dataSet: ~water_slices.dataSet, num_neighbours: 1);
    s.sync;
    ~water_slices.debug_tree = ~debug_kd_tree.(
        kd_tree: ~water_slices.kd_tree,
        dataSet: ~water_slices.dataSet,
        audio: ~water_slices.audio,
        slices: ~water_slices.slices,
        xmin: 0.0, xmax: 1.0, ymin: 0.0, ymax: 1
    );
});

);

(
~water_slices.dataSet.dump({
    |d|
    d["data"]["some_point0.0"].postln
});
)

// [ 0.011851277937637, 0.0036434348840783 ] the correct result!



// /* loaded */ d["data"]["0"] == [ 0.012941835448146, 0.07929140329361 ]


s.quit;

(
~make_kd_grain_listener_responder_synth = {
    |arg_pack|

    Routine({
        var listener_name = (arg_pack.id ++ '_listener').asSymbol;
        var synth_name = (arg_pack.id ++ '_synth').asSymbol;
        var responder_name = (arg_pack.id ++ '_responder').asSymbol;

        var relay_addr = ('/' ++ arg_pack.id ++ '/relay').asSymbol;

        arg_pack.input_buffer = Buffer.alloc(s, 2);
        arg_pack.reply_debug_bus = Bus.control(s,2);
        arg_pack.amp_bus = Bus.audio(s, 1);

        s.sync;


        SynthDef(listener_name, {
            var in = Mix.ar( SoundIn.ar(arg_pack.input_channels) );
            var spec = FluidSpectralShape.kr(in);
            var centroid = spec[0].cpsmidi;
            var spread = spec[1].abs.cpsmidi;

            var cen = centroid.linlin(\minCentroid.kr(20), \maxCentroid.kr(100), \minX.kr(0), \maxX.kr(1));
            var spre = spread.linlin(\minSpread.kr(10), \maxSpread.kr(24), \minY.kr(0), \maxY.kr(1));
            var amp = Amplitude.ar(in, attackTime: 0.1, releaseTime: 0.5)
            .linlin(\minAmp.kr(-50).dbamp.clip(0,1), \maxAmp.kr(-20).dbamp.clip(0,1), 0, 1);

            var out_raw = LPF.kr([cen,spre], \lpf.kr(1));
            var out = Gate.kr( out_raw, amp > \noiseFloorDb.kr(-30).dbamp.clip(0,1) );

            var out_bug = out.linlin([\minX.kr(), \minY.kr()], [\maxX.kr(), \maxY.kr()], 0, 1);


            Out.ar(arg_pack.amp_bus, amp);
            Out.kr(arg_pack.reply_debug_bus, out_bug);

            FluidKrToBuf.kr(out, arg_pack.input_buffer);
            SendReply.kr(trig: Impulse.kr(\replyFreq.kr(60)), cmdName: relay_addr, values: out);
        }).add;

        s.sync;
        arg_pack.listener_synth = Synth.new(defName: listener_name, target: arg_pack.target_group);
        s.sync;

        SynthDef(synth_name, {
            var num = 15;
            var upd_rate = \updateRate.kr(50);
            var new_grain = Dust.ar( upd_rate!num );
            var amp = In.ar(arg_pack.amp_bus, 1);
            //
            var g_dec = EnvGen.ar(
                Env.new(
                    [0, 1, 0],
                    [upd_rate.reciprocal * \fadeInF.kr(0.25), \fadeOutF.kr(0.75) * upd_rate.reciprocal],
                    \sine,
                    releaseNode: 2
                ),
                gate: new_grain > 0.000000001
            );
            var new_index = {
                var choice = ({(0..(arg_pack.kd_tree.numNeighbours - 1))}!num).flat;
                var raw = Select.ar(choice * \range.kr(1).clip(0,1), \index.ar(0!arg_pack.kd_tree.numNeighbours));
                Latch.ar(raw, new_grain);
            }.();
            //
            var start_frame = BufRd.ar(1, arg_pack.slices, new_index, loop:1, interpolation:1);
            var end_frame = BufRd.ar(1, arg_pack.slices,  new_index + 1, loop:1, interpolation:1);
            //
            var number_of_frames = end_frame - start_frame;
            var dur_of_frame = BufDur.ir(arg_pack.audio) / BufFrames.ir(arg_pack.audio);
            var duration = number_of_frames * dur_of_frame;
            //
            var imp = {
                var reg = Impulse.ar(duration.reciprocal * \overlap.kr(1), num.collect{|n| n / num});
                var ir = Dust.ar(duration.reciprocal * \overlap.kr(1), num.collect{|n| n / num});
                var f = \regularity.kr(1).clip(0,1);
                var se = Demand.ar(reg + ir, 0, Dwrand([0, 1], [f, 1 - f], inf));
                (reg * se) + (ir * (1 - se));
            }.();
            //
            var signal = GrainBuf.ar(1,
                imp,
                duration * \durScale.kr(1),
                arg_pack.audio,
                1.0,
                start_frame / BufFrames.ir(arg_pack.audio),
            );
            Out.ar(arg_pack.outBus, Splay.ar( LeakDC.ar(signal) * g_dec) * amp);

        }).add;

        s.sync;
        arg_pack.grain_synth = Synth(synth_name, target: arg_pack.listener_synth, addAction: 'addAfter');
        s.sync;

        OSCdef(responder_name, {
            |msg|
            arg_pack.kd_tree.kNearest(arg_pack.input_buffer, arg_pack.kd_tree.numNeighbours, {
                |index|
                if(index.class == Array,
                    {arg_pack.grain_synth.set(\index, index.collect{|i| i.asInteger })},
                    {arg_pack.grain_synth.set(\index, index.asInteger)}
                );
            });
        }, relay_addr, s.addr);


        arg_pack.free_please = {
            |self|
            self.grain_synth.free;
            self.listener_synth.free;
            OSCdef(responder_name).free;
            self.input_buffer.free();
            self.reply_debug_bus.free;
        };

    }).play;
};
)

s.freeAll

~l = {SoundIn.ar(0)!2 * -20.dbamp}.play;
~l.free;

~waterGrainA = (
    'id': 'waterGrainA',
    'kd_tree': ~water_slices.kd_tree,
    'dataSet': ~water_slices.dataSet,
    'audio': ~water_slices.audio,
    'slices': ~water_slices.slices,
    'input_channels' : [0],
    'target_group': s.asGroup,
    'outBus': 0,
    'debug_please': true
);


~make_kd_grain_listener_responder_synth.(~waterGrainA);

s.plotTree;
s.meter;

~waterGrainA.free_please();
~waterGrainA.mk_plotter(~waterGrainA.grain_synth)
~waterGrainA.reply_debug_bus.scope;


~waterGrainA.listener_synth.set(\minCentroid, 60);
~waterGrainA.listener_synth.set(\maxCentroid, 120);
~waterGrainA.listener_synth.set(\minSpread, 90);
~waterGrainA.listener_synth.set(\maxSpread, 120);

~waterGrainA.listener_synth.set(\minX, 0.05);
~waterGrainA.listener_synth.set(\maxX, 0.2);
~waterGrainA.listener_synth.set(\minY, 0.10);
~waterGrainA.listener_synth.set(\maxY, 0.2);

~waterGrainA.listener_synth.set(\lpf, 0.7);
~waterGrainA.listener_synth.set(\minAmp, -50);
~waterGrainA.listener_synth.set(\maxAmp, -25);
~waterGrainA.listener_synth.set(\noiseFloorDb, -40);

~waterGrainA.grain_synth.set(\updateRate, 20);
~waterGrainA.grain_synth.set(\regularity, 0.3);
~waterGrainA.grain_synth.set(\overlap, 1.0);
~waterGrainA.grain_synth.set(\fadeInF, 0.5);
~waterGrainA.grain_synth.set(\fadeOutF, 5);


s.quit;









(

SynthDef(\grain2, {
    var upd_rate = \updateRate.kr(0.5);
    var num = 15;
    var new_grain = Dust.ar( upd_rate!num );
    var g_dec = EnvGen.ar(
        Env.new(
            [0, 1, 0],
            [upd_rate.reciprocal * \fadeInF.kr(1), \fadeOutF.kr(1) * upd_rate.reciprocal],
            \sine,
            releaseNode: 2
        ),
        gate: new_grain > 0.000000001
    );
    var new_index = {
        var choice = ({(0..(~water_slices.kd_tree.numNeighbours - 1))}!num).flat;
        var raw = Select.ar(choice * \range.kr(1).clip(0,1), \index.ar(0!~water_slices.kd_tree.numNeighbours));
        Latch.ar(raw, new_grain);
    }.();
    //
    var start_frame = BufRd.ar(1, ~water_slices.slices, new_index, loop:1, interpolation:1);
    var end_frame = BufRd.ar(1, ~water_slices.slices,  new_index + 1, loop:1, interpolation:1);
    //
    var number_of_frames = end_frame - start_frame;
    var dur_of_frame = BufDur.ir(~water_slices.audio) / BufFrames.ir(~water_slices.audio);
    var duration = number_of_frames * dur_of_frame;
    //
    var imp = {
        var reg = Impulse.ar(duration.reciprocal * \overlap.kr(1,0, true), num.collect{|n| n / num});
        var ir = Dust.ar(duration.reciprocal * \overlap.kr(1,0, true), num.collect{|n| n / num});
        var f = \regularity.kr(1).clip(0,1);
        var se = Demand.ar(reg + ir, 0, Dwrand([0, 1], [f, 1 - f], inf));
        (reg * se) + (ir * (1 - se));
    }.();
    var signal = GrainBuf.ar(1,
        imp,
        duration * \durScale.kr(1, 0, true),
        ~water_slices.audio,
        1.0,
        start_frame / BufFrames.ir(~water_slices.audio),
    );
    Out.ar(0, Splay.ar( LeakDC.ar(signal) * g_dec));
}).add;
)

~grain = Synth(\grain2);
(
~grain.set(\overlap, 1);
~grain.set(\updateRate, 20);
~grain.set(\regularity, 0);
~grain.set(\fadeInF, 0.75);
~grain.set(\fadeOutF, 0.25);
)
~grain.free

~grain.set(\index, 81)

s.meter
~water_slices.dataSet
~water_slices.debug_tree.mk_plotter(~grain);


~water_slices.dataSet

~b = Buffer(s);
~l = FluidLabelSet(s);

~water_slices.dataSet.toBuffer(~b, 0, ~l)
~l.write("/home/jordan/Desktop/testb_label")
~b.write("/home/jordan/Desktop/testb.aiff", sampleFormat:"float");

~b.plot

~e = FluidDataSet(s)
~e.print
~e.fromBuffer(~b, 0, ~l)

~water_slices.dataSet.print




~l.asJSON


~b_file = Buffer.read(s, "/home/jordan/Desktop/testb.aiff")
~b.plot
~b_file.plot

~l_file = FluidLabelSet(s);
~l_file.read("/home/jordan/Desktop/testb_label")
~l_file.print


~d = FluidDataSet(s);



t = Dictionary.newFrom([\a, 1, \b, 5]).asCompileString
t.interpret
t.interpret.keysValuesDo{|k,v| [k,v].postln }

(\a:1, \b:2).asCompileString



"~".asAbsolutePath





~water_slices.debug_tree.plotter.ymax_(0.0015);
~water_slices.debug_tree.plotter.xmax_(0.5);
~water_slices.debug_tree.plotter.pointSizeScale_(0.5);

