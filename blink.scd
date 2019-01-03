
(
SynthDef("listen", { | input = 1|
	var sig, onsets;
	sig    = SoundIn.ar(input);
	onsets = Onsets.kr(FFT(LocalBuf(512), sig), 0.05, \rcomplex);
	SendTrig.kr(onsets,input,Timer.kr(onsets));
}
).add
)
o = Server.local.options;
o.numOutputBusChannels.postln;
o.numInputBusChannels = 12;
o.numOutputBusChannels = 12;
(
SynthDef(\bell, {
	|fs=1, t60=1, pitchy=1, amp=0.25, gate=1, out=0|
	var sig, exciter;
	exciter = WhiteNoise.ar() * EnvGen.ar(Env.perc(0.001, 0.02), gate) * 0.25;
	sig = Klank.ar(
		`[
			[1, 2, 2.803, 3.871, 5.074, 7.81, 10.948, 14.421],   // freqs
			[1, 0.044, 0.891, 0.0891, 0.794, 0.1, 0.281, 0.079], // amplitudes
			[1, 0.205, 1, 0.196, 0.339, 0.047, 0.058, 0.047]*t60;     // ring times
		],
		exciter,
		freqscale:fs*pitchy);
	sig = FreeVerb.ar(sig) * amp * 0.6;
	DetectSilence.ar(sig * amp, 0.001, 0.5, doneAction:2);
	Out.ar(out, sig);
}).add
)

Synth(\bell, [\fs, 100, \t60, 1.0, \pitchy, 3.0, \out, 0, \amp, 0.07]);

// The age of the agent can evolve over lifecycle
// Synchronisation can lead to longer life - indefinite?
// Sound can evolve from blips to tonal
// Do I need a hard reset where everything starts from the beginning?

Server.freeAll
(
8.do({arg z; ({
	x = Routine.new({
		var t = 1.0;
        var skip = t.rand;
		var seconds = 0.0;
		var self = z;
		var onsets = Synth.tail(s,\listen, [\input, self]);
		var a = 1.22140275816016983392;
		var b = 0.08606747492355714203;
        var inSync = false;
        var t60 = 0.2;
		o = OSCFunc({ arg msg, time;
			if(msg[2] == self){
                ("Got message for " + self).postln;
                // msg.postln;
				if(abs(msg[3] - t) > 0.1){
					skip = min(1.0,a * (SystemClock.seconds - seconds) + b);
                    // "adjusting: ".post;
                    // skip.postln;
				}{
                    (self + " in sync").postln;
                    inSync = true;
                    skip = 0;
                };
		}
	},'/tr', s.addr);

		loop{
			seconds = SystemClock.seconds;
            if(inSync){
                t60 = min(1.0,t60 + 0.1);
            }{t60 = max(0.1,t60-0.1);};
            Synth.head(s, \bell, [\fs, 10+(100*self), \t60, t60 , \pitchy, 2.0,  \out,self, \amp, 0.3]);
			(t-skip).wait;
            skip = skip * 0.1;
		};

	});
	x.play
}.value
)
})
)


// -- overlap texture 2
(
SynthDef("help-KlankOverlapTexture2",
{|out = 0, freqs = #[0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0], rings = #[0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0], atk = 5, sus = 8, rel = 5, pan = 0|
    var e = EnvGen.kr(Env.linen(atk, sus, rel, 1, 4), doneAction:2);
    var i = BrownNoise.ar(0.0012);
    var z = Klank.ar(
        `[freqs, nil, rings],     // specs
        i                    // input
    );
    Out.ar(out, Pan2.ar(z*e, pan));
}).add;

r = Routine{
    var sustain = 6, transition = 4, overlap = 5;
    var period = transition*2+sustain/overlap;
    0.5.wait;            // wait for the synthdef to be sent to the server
    inf.do {
        Synth("help-KlankOverlapTexture2", [
            \atk, transition,
            \sus, sustain,
            \rel, transition,
            \pan, 1.0.rand2,
            \freqs, {6000.0.linrand+80}.dup(12),
            \rings, {0.1.rrand(3)}.dup(12),
            \out, [8,9]
        ]);
        period.wait;
    }
};
r.play;
)
r.stop