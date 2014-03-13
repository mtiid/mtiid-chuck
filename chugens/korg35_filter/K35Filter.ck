// virtual analog Korg35 low pass filter
// ported from Will Pirkle's app notes and project files:
// http://www.willpirkle.com/project-gallery/app-notes/#AN5
// ported by Bruce Lott, december 2013

public class K35Filter extends Chugen{
    K35OnePoleFilter m_LPF1;
    K35OnePoleFilter m_LPF2;
    K35OnePoleFilter m_HPF1;
    
    float m_dFc;
    float m_dK;
    float m_dAlpha0;   // u scalar value
    float m_dSaturation;
    float m_nSampleRate;
    int nonLinearProcessing;
    
    // functions:
    fun float saturation(float s){
        if(s>0 & s<10) s => m_dSaturation;
        return m_dSaturation;
    }
    
    fun int nonLinearity(int nl){
        if(nl != 0) 1 => nonLinearProcessing;
        else 0 => nonLinearProcessing;
        return nonLinearProcessing;
    }
    
    fun float tick(float in){
        return doFilter(in);
    }
    
    fun float q(){ return m_dK; }
    fun float q(float nq){
        nq => m_dK;
        updateFilters();
        return m_dK;
    }
    
    fun float cutoff(){ return m_dFc; }
    fun float cutoff(float cf){
        cf => m_dFc;
        updateFilters();
        return m_dFc;
    }
    
    fun void init(){
        second/samp => m_nSampleRate;
        20000 => m_dFc;
        1 => m_dK;
        nonLinearity(0);
        saturation(1);
        updateFilters();
    }
    
    fun void updateFilters(){
        // use this is f you want to let filters update themselves;
        // since we calc everything here, it would be redundant
        
        // prewarp for BZT
        2.0*pi*m_dFc => float wd;          
        1.0/m_nSampleRate => float T;             
        (2.0/T)*Math.tan(wd*T/2.0) => float wa; 
        wa*T/2.0 => float g; 
        // G - the feedforward coeff in the VA One Pole
        g/(1.0 + g) => float G;
        // set alphas
        G => m_LPF1.m_fAlpha;
        G => m_LPF2.m_fAlpha;
        G => m_HPF1.m_fAlpha;
        // set betas all are in the form of  <something>/((1 + g)
        (m_dK - m_dK*G)/(1.0 + g) => m_LPF2.m_fBeta;
        -1.0/(1.0 + g) => m_HPF1.m_fBeta;
        // set m_dAlpha0 variable
        1.0/(1.0 - m_dK*G + m_dK*G*G) => m_dAlpha0;
    }
    
    fun void prepareForPlay(){
        // set types
        0 => m_LPF1.filterType;
        0 => m_LPF2.filterType;
        1 => m_HPF1.filterType;
        // flush everything
        m_LPF1.reset();
        m_LPF2.reset();
        m_HPF1.reset();
        // set initial coeff states
        updateFilters();
    }
    
    fun float doFilter(float xn){
        
        // process input through LPF1
        m_LPF1.doFilter(xn) => float y1;
        // form feedback value
        m_HPF1.getFeedbackOutput() + m_LPF2.getFeedbackOutput() => float S35; 
        // calculate u
        m_dAlpha0*(y1 + S35) => float u;
        // NAIVE NLP
        if(nonLinearProcessing == 1)
        {
            // regular version
            Math.tanh(m_dSaturation*u) => u;
        }
        // feed it to LPF2
        m_dK*m_LPF2.doFilter(u) => float y;
        // feed y to HPF
        m_HPF1.doFilter(y);
        // auto-normalize
        if(m_dK > 0) 1/m_dK *=> y;
        
        return y;
    }
}

class K35OnePoleFilter{
    // common variables
    float m_fSampleRate;	// sample rate
    float m_fFc;			// cutoff frequency
    int filterType;         // 0 = LP, 1 = HP
    
    // trapezoidal integrator components
    float m_fAlpha;			// feed forward coeff
    float m_fBeta;			// feed back coeff
    
    //z-1
    float m_fZ1;
    
    //  ------ functions ------
    // initializer
    fun void init(){
        1.0 => m_fAlpha;
        1.0 => m_fBeta;
        second/samp => m_fSampleRate;
        0 => filterType;
        reset();
    }
    
    // provide access to our feedback output
    fun float getFeedbackOutput(){ return m_fZ1*m_fBeta; }
    
    // -- CFilter Overrides --
    fun void reset(){ 0 => m_fZ1; }
    
    // recalc the coeff -- NOTE: not used for Korg35 Filter
    fun void updateFilter(){ 
        2.0*pi*m_fFc => float wd;          
        1.0/m_fSampleRate => float T;             
        (2.0/T)*Math.tan(wd*T/2.0) => float wa; 
        wa*T/2.0 => float g;     
        g/(1.0 + g) => m_fAlpha;
    }
    
    // do the filter
    fun float doFilter(float xn){
        (xn - m_fZ1)*m_fAlpha => float vn; // calculate v(n)
        vn + m_fZ1 => float lpf;           // form LP output
        vn + lpf => m_fZ1;                 // update memory
        xn - lpf => float hpf;             // do the HPF
        if(filterType == 0){     // filter type to return
            return lpf;
        }
        else if(filterType == 1) return hpf;
        else return lpf;
    }
}
1::second => now;