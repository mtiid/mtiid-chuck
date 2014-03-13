// a simple demo of the diode ladder filter
// lfo on the cutoff frequency
// by Bruce Lott, 2013

SawOsc saw => CVADiodeLadderFilter diode => dac;
200 => saw.freq;
0.5 => saw.gain;

diode.init();
diode.cutoff(16000); // set filter cutoff in hertz
diode.q(16);  // min is 0, max is 17 which self resonates

SinOsc lfo => blackhole;
0.05 => lfo.freq;

while(samp=>now) diode.cutoff(lfo.last() * 1000 + 1100);