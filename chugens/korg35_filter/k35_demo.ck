// a simple demo of the k35 filter
// lfo on the cutoff frequency
// by Bruce Lott, 2013

SawOsc saw => K35Filter k35 => dac;
200 => saw.freq;
0.5 => saw.gain;

k35.init();
k35.cutoff(1000);
k35.nonLinearity(0);
k35.q(1.95); // min is 0, max is 2 which self resonates

SinOsc lfo => blackhole;
0.05 => lfo.freq;

while(samp=>now) k35.cutoff(lfo.last() * 1000 + 1100);