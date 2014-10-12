// Quneo.ck
// Dexter Shepherd and Eric Heep
// CalArts Music Tech // MTIID4LIFE
// class for communicating with ChucK and a Quneo

public class Quneo{
    
    int pad[16];
    int padX[16];
    int padY[16];
    int padZ[16];
    int slider[10];
    int button[13];
    int play, stop, diamond, fader;
    
    int padLEDRed[16];
    [0,2,4,6,8,10,12,14,16,18,20,22,24,26,28,30] @=> int padLEDGreen[];
    
    int port;
    MidiIn min[10];
    MidiOut mout[10];
    MidiMsg msgIn;
    MidiMsg msgOut;
    
    spork ~ update();
    
    for (int i; i < min.cap(); i++) {
        // no print err
        min[i].printerr(0);
        
        // open the device
        if (min[i].open(i)) {
            if (min[i].name() == "QUNEO") {
                i => port;
                <<< "Connected to", min[port].name(), "" >>>;
            }
        }
        else break;
    } 
    
    // input
    fun void update() {
        while (true) {
            // waits on midi events
            min[port] => now;
            while (min[port].recv(msgIn)) {
                getValues(msgIn.data1, msgIn.data2, msgIn.data3);
            }
        }
    }
    
    // convert values
    fun void getValues(int data1, int data2, int data3){
        if((data1 == 144)||(data1 == 128)){
            for (int i; i < 16; i++){
                if(data2 == i){
                    data3 => pad[i];
                }
            }
        }
        if (data1 == 176) {
            if (data2 == 10) {
                data3 => fader;
            }
            for (int i; i < 10; i++) {
                if (data2 == i) {
                    data3 => slider[i];
                }
            }
            for (int i; i < 13; i++) {
                if (data2 == i + 71) {
                    data3 => button[i];
                }
            }
            if (data2 == 84) {
                data3 => diamond;
            }
            if (data2 == 85) {
                data3 => stop;
            }
            if (data2 == 86) {
                data3 => play;
            }
        }
        
        /*
        for (int i; i < 16; i++){
            if(data2 == i + 16){
                data3 => padZ[i];
            }
            else if(data2 == i + 32){
                data3 => padX[i];
            }
            else if(data2 == i + 48) {
                data3 => padY[i];
            }
            else if(data2 == i + 64) {
                data3 => slider[i];
            }
        }
        */
    }
    
    // output Functions
    fun void padLEDOn(int padNumber, int color, int brightness){
        144 => msgOut.data1;
        if(color == 0){
            padLEDGreen[padNumber] => msgOut.data2;
        }
        else if(color == 1){
            padLEDRed[padNumber] => msgOut.data2;
        }
        brightness => msgOut.data3;
        
        mout[port].send(msgOut);
    }
    
    fun void padLEDOff(int padNumber, int color){
        128 => msgOut.data1;
        
        if(color == 0){
            padLEDGreen[padNumber] => msgOut.data2;
        }
        else if(color == 1){
            padLEDRed[padNumber] => msgOut.data2;
        }
        
        0 => msgOut.data3;
        
        mout[port].send(msgOut);
    }
}