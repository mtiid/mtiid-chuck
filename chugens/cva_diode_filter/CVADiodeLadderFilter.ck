// Virtual Analog Diode Ladder Filter 
// Ported from Will Pirkle's app notes/C++ project files:
// http://www.willpirkle.com/project-gallery/app-notes/#AN6
// ported by Bruce Lott, Ness Morris, and Owen Vallis
// December 2013
public class CVADiodeLadderFilter extends Chugen{
    CVAOnePoleFilter m_LPF1;
    CVAOnePoleFilter m_LPF2;
    CVAOnePoleFilter m_LPF3;
    CVAOnePoleFilter m_LPF4;
    
    // our feedback S values (global)
    float m_dSG1; 
    float m_dSG2; 
    float m_dSG3; 
    float m_dSG4; 
    
    float m_dGAMMA; // Gamma see App Note 
    float m_dK;             //resonance
    float m_dFc;            //filter cutoff freq
    float m_nSampleRate; 
    float m_dSaturation;
    int m_uNLPType;         //nonlinearity type
    int m_NonLinearProcessing;
    
    //Functions
    fun float q(){ return m_dK; }
    fun float q(float nq){
        nq => m_dK;
        updateFilter();
        return m_dK;
    }
    
    fun float cutoff(){ return m_dFc; }
    fun float cutoff(float nfc){
        nfc => m_dFc;
        updateFilter();
        return m_dFc;
    }
    
    fun void init(){
        second/samp => m_nSampleRate;
        4 => m_dSaturation;
        1 => m_NonLinearProcessing;
        1 => m_uNLPType;
        1 => m_dK;
        // filter coeffs that are constant
        // set a0s
        1.0 => m_LPF1.m_da0;
        0.5 => m_LPF2.m_da0;
        0.5 => m_LPF3.m_da0;
        0.5 => m_LPF4.m_da0;
        // last LPF has no feedback path
        1.0 => m_LPF4.m_dGamma;
        m_LPF4.setFeedback(0.0);
        
        reset();
        updateFilter();
        cutoff(20000);
        q(0.1);
    }
    
    fun void reset(){
        m_LPF1.reset(); m_LPF2.reset();
        m_LPF3.reset(); m_LPF4.reset();
        m_LPF1.setFeedback(0.0); m_LPF2.setFeedback(0.0); 
        m_LPF3.setFeedback(0.0); m_LPF4.setFeedback(0.0); 
    }
    
    // recalc the coeffs
    fun void updateFilter(){
        // calculate alphas
        2.0*pi*m_dFc => float wd; 
        1.0/m_nSampleRate => float T;
        (2.0/T)*Math.tan(wd*T/2.0) => float wa; 
        wa*T/2.0 => float g;
        // Big G's
        float G1, G2, G3, G4;
        (0.5*g)/(1.0 + g) => G4;
        (0.5*g)/(1.0 + g - 0.5*g*G4) => G3;
        (0.5*g)/(1.0 + g - 0.5*g*G3) => G2;
        g/(1.0 + g - g*G2) => G1;
        
        // our big G value GAMMA
        G4*G3*G2*G1 => m_dGAMMA;
        
        G4*G3*G2 => m_dSG1; 
        G4*G3 => m_dSG2; 
        G4 => m_dSG3; 
        1.0 => m_dSG4; 
        // set alphas
        g/(1.0 + g) => m_LPF1.m_dAlpha;
        g/(1.0 + g) => m_LPF2.m_dAlpha;
        g/(1.0 + g) => m_LPF3.m_dAlpha;
        g/(1.0 + g) => m_LPF4.m_dAlpha;
        // set betas
        1.0/(1.0 + g - g*G2) => m_LPF1.m_dBeta;
        1.0/(1.0 + g - 0.5*g*G3) => m_LPF2.m_dBeta;
        1.0/(1.0 + g - 0.5*g*G4) => m_LPF3.m_dBeta;
        1.0/(1.0 + g) => m_LPF4.m_dBeta ;
        
        // set gammas
        1.0 + G1*G2 => m_LPF1.m_dGamma;
        1.0 + G2*G3 => m_LPF2.m_dGamma;
        1.0 + G3*G4 => m_LPF3.m_dGamma;
        // m_LPF4.m_dGamma = 1.0; // constant - done in constructor
        
        // set deltas
        g => m_LPF1.m_dDelta;
        0.5*g => m_LPF2.m_dDelta;
        0.5*g => m_LPF3.m_dDelta;
        // m_LPF4.m_dDelta = 0.0; // constant - done in constructor
        // set epsilons
        G2 => m_LPF1.m_dEpsilon;
        G3 => m_LPF2.m_dEpsilon;
        G4 => m_LPF3.m_dEpsilon;
        // m_LPF4.m_dEpsilon = 0.0; // constant - done in constructor 
    }
    
    fun float tick(float in){
        return doFilter(in);
    }
    
    // do the filter
    fun float doFilter(float xn){
        // m_LPF4.setFeedback(0.0); // constant - done in constructor
        m_LPF3.setFeedback(m_LPF4.getFeedbackOutput());
        m_LPF2.setFeedback(m_LPF3.getFeedbackOutput());
        m_LPF1.setFeedback(m_LPF2.getFeedbackOutput());
        // form input
        m_dSG1*m_LPF1.getFeedbackOutput() + 
        m_dSG2*m_LPF2.getFeedbackOutput() +
        m_dSG3*m_LPF3.getFeedbackOutput() +
        m_dSG4*m_LPF4.getFeedbackOutput() => float SIGMA;
        
        //"cheap" nonlinear model; just process input
        if(m_NonLinearProcessing > 0)
        {
            //Normalized Version
            if(m_uNLPType > 0)
                (1.0/Math.tanh(m_dSaturation))*Math.tanh(m_dSaturation*xn) => xn;
            else
                Math.tanh(m_dSaturation*xn) => xn;
        }
        
        // form the input to the loop
        (xn - m_dK*SIGMA)/(1.0 + m_dK*m_dGAMMA) => float un;
        // cascade of series filters
        return m_LPF4.doFilter(m_LPF3.doFilter(m_LPF2.doFilter(m_LPF1.doFilter(un))));
    }
}

class CVAOnePoleFilter{
    // common variables
    second/samp => float m_dSampleRate; // sample rate
    float m_dFc;  // cutoff frequency
    
    // Trapezoidal Integrator Components
    // variables
    float m_dAlpha;  // Feed Forward coeff
    float m_dBeta;  // Feed Back coeff from s + FB_IN
    // extended functionality variables
    float m_dGamma;  // Pre-Gain
    float m_dDelta;  // FB_IN Coeff
    float m_dEpsilon;  // extra factor for local FB
    float m_da0;  // filter gain
    float m_dFeedback; // Feed Back storage register (not a delay register)
    float m_dZ1; // our z-1 storage location
    
    //Functions
    fun void init(){
        1.0 => m_dAlpha;
        -1.0 => m_dBeta;
        1.0 => m_dGamma;
        1.0 => m_dEpsilon;
        1.0 => m_da0;
        reset();
    }
    // provide access to our feedback output
    fun float getFeedbackOutput(){ 
        return m_dBeta*(m_dZ1 + m_dFeedback*m_dDelta); 
    }  
    // provide access to set our feedback input
    fun void setFeedback(float fb){ fb => m_dFeedback;}
    // for s_N only; not used in the Diode Ladder
    fun float getStorageValue(){ return m_dZ1; }
    // flush buffer
    fun void reset(){ 0 => m_dZ1; }
    
    fun float doFilter(float xn){        
        (xn*m_dGamma + m_dFeedback + m_dEpsilon*getFeedbackOutput()) => float x_in;
        (m_da0*x_in - m_dZ1)*m_dAlpha => float vn;
        vn + m_dZ1 => float out;
        vn + out => m_dZ1;
        
        return out;
    }
}