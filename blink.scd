
(
SynthDef("listen", { | input = 1|
	var sig, onsets;
	sig    = In.ar(input);
	// sig = In.ar(input);
	onsets = Onsets.kr(FFT(LocalBuf(512), sig), 0.4, \rcomplex);
	SendTrig.kr(onsets,input,Timer.kr(onsets));
}
).add;


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

o = Server.default.options;
o.numInputBusChannels = 12;
o.numOutputBusChannels = 12;

(
w = Window("Blink",600@600);
w.front;
w.view.decorator = FlowLayout(w.view.bounds);
w.view.decorator.gap=4@4;

10.do({arg z; ({
	x = Routine.new({
		var t = 1.0;
		var skip = t.rand;
		var seconds = 0.0;
		var self = z;
		var thresh = 0.3;
		var amp = 0.2;
		var oldAmp = amp;
		var onsets = Synth.tail(s,\listen, [\input, z, \thresh, thresh]);
		var a = 1.22140275816016983392;
		var b = 0.08606747492355714203;
		var inSync = false;
		var t60 = 0.2;
		var buffer = Buffer.alloc(s,1024,2);
		
		{
			EZSlider(w,400 @ 20, "Thresh-" + z, ControlSpec(0.01,1.0,\lin,0,0.5), {|ez| onsets.set(\thresh, ez.value)});
			EZSlider(w,400 @ 20, "Amp-" + z, ControlSpec(0.0,1.0,\lin,0,0.5), {|ez| amp = ez.value});
			c = CheckBox(w,20@20, "mute");
			c.action_{|x| if(x.value == true){ "muting".postln;oldAmp = amp; amp = 0;}{amp = oldAmp;}};
		}.defer;
		
		o = OSCFunc({ arg msg, time;
			if(msg[2] == z){
				{w.view.children[z*3].background = Color.blue;}.defer;
				AppClock.sched(0.1,{arg time;
					w.view.children[z*3].background = Color.white;
				nil;
				});
				if(abs(msg[3] - t) > 0.1){
					skip = min(1.0,(a * (SystemClock.seconds - seconds) + b));
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
			Synth.head(s, \bell, [\fs, 200 + (200 * self), \t60, t60 , \pitchy, 2.0,  \out,self, \amp, amp]);
			(t-skip).wait;
			skip = skip * 0.1;
		};
		
	});
	x.play
}.value
)

});

)
