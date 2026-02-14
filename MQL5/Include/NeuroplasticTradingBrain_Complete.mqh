//+------------------------------------------------------------------+
//|                                    NeuroplasticTradingBrain.mqh |
//|                          Production-Grade Adaptive Brain v2.0   |
//|                              Bulletproofed Neural Architecture  |
//+------------------------------------------------------------------+
#property copyright "Neuroplastic Trading Framework v2.0"
#property version   "2.00"
#property strict

#include <Arrays\ArrayObj.mqh>

//+------------------------------------------------------------------+
//| System Constants & Safety Limits                                |
//+------------------------------------------------------------------+
#define BRAIN_VERSION           "2.0.0"
#define MAX_MEMORY_SIZE         5000
#define MIN_LEARNING_RATE       0.0001
#define MAX_LEARNING_RATE       0.1
#define MOMENTUM_CLAMP          10.0
#define CACHE_EXPIRY_TICKS      10
#define CHECKPOINT_MAGIC        0x4E455552  // 'NEUR'
#define TRM_HIDDEN_SIZE         8           // Zenith: Fixed hidden size for stack alloc

//+------------------------------------------------------------------+
//| Memory Structure with validation                                |
//+------------------------------------------------------------------+
struct TradeMemory {
    datetime timestamp;
    double   entryPrice;
    double   exitPrice;
    double   volume;
    int      direction;
    double   profit;
    double   drawdown;
    string   pattern;
    double   confidence;
    double   learningValue;
    int      references;
    ulong    checksum;
    double   features[20]; // Zenith: Store context for replay

    void Initialize() {
        timestamp = 0;
        entryPrice = 0;
        exitPrice = 0;
        volume = 0;
        direction = 0;
        profit = 0;
        drawdown = 0;
        pattern = "";
        confidence = 0;
        learningValue = 0;
        references = 0;
        checksum = 0;
        ArrayInitialize(features, 0.0);
    }

    ulong CalculateChecksum() {
        return (ulong)timestamp ^
               (ulong)(entryPrice * 1000000) ^
               (ulong)(exitPrice * 1000000) ^
               (ulong)(profit * 1000);
    }

    bool Validate() {
        return checksum == CalculateChecksum();
    }
};

//+------------------------------------------------------------------+
//| Synaptic Connection with safety checks                          |
//+------------------------------------------------------------------+
struct SynapticConnection {
    int    fromModule;
    int    toModule;
    double weight;
    double plasticity;
    int    activations;
    datetime lastUpdate;

    void Initialize(int from, int to) {
        fromModule = from;
        toModule = to;
        weight = 0.25;
        plasticity = 0.1;
        activations = 0;
        lastUpdate = 0;
    }

    void UpdateWeight(double delta) {
        weight = MathMax(-1.0, MathMin(1.0, weight + delta));
        lastUpdate = TimeCurrent();
    }
};

//+------------------------------------------------------------------+
//| Thread-safe Cache System                                        |
//+------------------------------------------------------------------+
class CCache {
private:
    struct CacheEntry {
        double value;
        datetime timestamp;
        bool valid;
        string key;
    };

    CacheEntry m_entries[];
    int m_maxEntries;

public:
    CCache() {
        m_maxEntries = 100;
        ArrayResize(m_entries, m_maxEntries);
        InvalidateAll();
    }

    bool Get(string key, double &value) {
        for(int i = 0; i < m_maxEntries; i++) {
            if(m_entries[i].valid && m_entries[i].key == key) {
                if(TimeCurrent() - m_entries[i].timestamp < CACHE_EXPIRY_TICKS) {
                    value = m_entries[i].value;
                    return true;
                }
                m_entries[i].valid = false;
            }
        }
        return false;
    }

    void Set(string key, double value) {
        int slot = -1;
        for(int i = 0; i < m_maxEntries; i++) {
            if(!m_entries[i].valid || m_entries[i].key == key) {
                slot = i;
                break;
            }
        }

        if(slot >= 0) {
            m_entries[slot].key = key;
            m_entries[slot].value = value;
            m_entries[slot].timestamp = TimeCurrent();
            m_entries[slot].valid = true;
        }
    }

    void InvalidateAll() {
        for(int i = 0; i < m_maxEntries; i++) {
            m_entries[i].valid = false;
        }
    }
};

//+------------------------------------------------------------------+
//| Meta-Learning Module with safety bounds                         |
//+------------------------------------------------------------------+
class CMetaLearner {
private:
    double m_learningRate;
    double m_adaptationSpeed;
    double m_curiosityFactor;
    double m_performanceHistory[];
    int    m_learningCycles;
    CCache m_cache;

    double SafeDivide(double numerator, double denominator) {
        if(MathAbs(denominator) < 0.0000001) return 0;
        return numerator / denominator;
    }

public:
    CMetaLearner() {
        m_learningRate = 0.01;
        m_adaptationSpeed = 0.1;
        m_curiosityFactor = 0.3;
        m_learningCycles = 0;
        ArrayResize(m_performanceHistory, 1000);
    }

    double OptimizeLearningRate(double currentPerformance) {
        if(!MathIsValidNumber(currentPerformance)) {
            Print("WARNING: Invalid performance value");
            return m_learningRate;
        }

        double cached;
        string cacheKey = "lr_" + DoubleToString(currentPerformance, 4);
        if(m_cache.Get(cacheKey, cached)) {
            return cached;
        }

        if(m_learningCycles < ArraySize(m_performanceHistory)) {
            m_performanceHistory[m_learningCycles] = currentPerformance;
        } else {
            ArrayCopy(m_performanceHistory, m_performanceHistory, 0, 1);
            m_performanceHistory[ArraySize(m_performanceHistory)-1] = currentPerformance;
        }

        if(m_learningCycles > 10) {
            double gradient = CalculateGradient();

            if(!MathIsValidNumber(gradient)) {
                gradient = 0;
            }

            double adjustment = gradient * m_adaptationSpeed;
            adjustment = MathMax(-0.5, MathMin(0.5, adjustment));

            if(gradient > 0) {
                m_learningRate *= (1 + adjustment);
            } else {
                m_learningRate *= (1 - MathAbs(adjustment) * 0.5);
            }

            double exploration = m_curiosityFactor * (MathRand() / 32768.0 - 0.5) * 0.001;
            m_learningRate += exploration;
        }

        m_learningCycles++;
        m_learningRate = MathMax(MIN_LEARNING_RATE, MathMin(MAX_LEARNING_RATE, m_learningRate));

        m_cache.Set(cacheKey, m_learningRate);

        return m_learningRate;
    }

    double CalculateGradient() {
        int samples = MathMin(10, m_learningCycles);
        if(samples < 2) return 0;

        double sumXY = 0, sumX = 0, sumY = 0, sumX2 = 0;

        for(int i = m_learningCycles - samples; i < m_learningCycles; i++) {
            if(i >= 0 && i < ArraySize(m_performanceHistory)) {
                double x = i;
                double y = m_performanceHistory[i];
                sumXY += x * y;
                sumX += x;
                sumY += y;
                sumX2 += x * x;
            }
        }

        double denominator = samples * sumX2 - sumX * sumX;
        return SafeDivide(samples * sumXY - sumX * sumY, denominator);
    }

    void UpdateCuriosity(double novelty) {
        novelty = MathMax(0, MathMin(1, novelty));
        m_curiosityFactor = 0.3 + 0.2 * novelty;
        m_curiosityFactor = MathMin(m_curiosityFactor, 0.7);
    }

    double GetLearningRate() { return m_learningRate; }

    void SaveState(int handle) {
        FileWriteDouble(handle, m_learningRate);
        FileWriteDouble(handle, m_adaptationSpeed);
        FileWriteDouble(handle, m_curiosityFactor);
        FileWriteInteger(handle, m_learningCycles);
    }

    void LoadState(int handle) {
        m_learningRate = FileReadDouble(handle);
        m_adaptationSpeed = FileReadDouble(handle);
        m_curiosityFactor = FileReadDouble(handle);
        m_learningCycles = FileReadInteger(handle);
    }
};

//+------------------------------------------------------------------+
//| Tiny Recursive Model (TRM) with MGU Cells                       |
//| Replaces shallow perceptron with recursive logic                |
//+------------------------------------------------------------------+
class CTinyRecursiveModel {
private:
    // Hyperparameters
    const int m_inputSize;
    const int m_hiddenSize;
    const int m_outputSize;
    const int m_recurrenceSteps;

    // Weights (Flattened for O(1) access)
    // MGU Gates: f (forget), h (hidden candidate)
    // W_f: [InputSize * HiddenSize]
    // U_f: [HiddenSize * HiddenSize]
    // b_f: [HiddenSize]
    // W_h: [InputSize * HiddenSize]
    // U_h: [HiddenSize * HiddenSize]
    // b_h: [HiddenSize]
    // W_y: [HiddenSize * OutputSize]
    // b_y: [OutputSize]
    double m_Wf[], m_Uf[], m_bf[];
    double m_Wh[], m_Uh[], m_bh[];
    double m_Wy[], m_by[];

    // State
    double m_h[];     // Current hidden state (z)
    double m_y[];     // Current output (y)
    double m_confidence;

    // Gradient Accumulators (for batch learning simulation)
    double m_grad_Wf[], m_grad_Uf[], m_grad_bf[];
    double m_grad_Wh[], m_grad_Uh[], m_grad_bh[];
    double m_grad_Wy[], m_grad_by[];

    // Math Helpers
    double Sigmoid(double x) { return 1.0 / (1.0 + MathExp(-x)); }
    double Tanh(double x) { return MathTanh(x); }
    double SigmoidDerivative(double x) { double s = Sigmoid(x); return s * (1 - s); }
    double TanhDerivative(double x) { double t = Tanh(x); return 1 - t * t; }

    void InitializeWeights() {
        double scale = MathSqrt(2.0 / (m_inputSize + m_hiddenSize));
        RandomizeArray(m_Wf, scale); RandomizeArray(m_Uf, scale); RandomizeArray(m_bf, 0.01);
        RandomizeArray(m_Wh, scale); RandomizeArray(m_Uh, scale); RandomizeArray(m_bh, 0.01);
        RandomizeArray(m_Wy, scale); RandomizeArray(m_by, 0.01);
    }

    void RandomizeArray(double &arr[], double scale) {
        for(int i=0; i<ArraySize(arr); i++) {
            arr[i] = (MathRand()/32767.0 - 0.5) * 2 * scale;
        }
    }

public:
    CTinyRecursiveModel() : m_inputSize(20), m_hiddenSize(TRM_HIDDEN_SIZE), m_outputSize(1), m_recurrenceSteps(3) {
        ArrayResize(m_Wf, m_inputSize * m_hiddenSize);
        ArrayResize(m_Uf, m_hiddenSize * m_hiddenSize);
        ArrayResize(m_bf, m_hiddenSize);

        ArrayResize(m_Wh, m_inputSize * m_hiddenSize);
        ArrayResize(m_Uh, m_hiddenSize * m_hiddenSize);
        ArrayResize(m_bh, m_hiddenSize);

        ArrayResize(m_Wy, m_hiddenSize * m_outputSize);
        ArrayResize(m_by, m_outputSize);

        ArrayResize(m_h, m_hiddenSize);
        ArrayResize(m_y, m_outputSize);

        InitializeWeights();
        ArrayInitialize(m_h, 0.0);
        m_confidence = 0.5;
    }

    // Forward Pass: Recursive "Thinking" Loop
    // Phase 1 (Reasoning): Update z (m_h) multiple times based on x, y, z
    // Phase 2 (Refinement): Update y (m_y) based on z
    double Forward(double &features[]) {
        if(ArraySize(features) != m_inputSize) {
            // Handle resizing if features changed (dynamic input size)
            // Ideally avoid dynamic resizing in Zenith standard, but for safety:
            return 0.5;
        }

        // --- Phase 1: Latent Reasoning (Recursive Steps) ---
        // z_new = MGU(x, z_old) repeated N times
        // Note: Standard MGU takes input x_t at each step t.
        // Here, x is static for the "thinking" duration.

        // Temp buffers for MGU calculation to avoid allocs inside loop
        double f_gate[TRM_HIDDEN_SIZE]; // Matches m_hiddenSize
        double h_tilde[TRM_HIDDEN_SIZE];

        for(int step=0; step < m_recurrenceSteps; step++) {
            // 1. Forget Gate: f = Sigmoid(Wf*x + Uf*h + bf)
            for(int j=0; j<m_hiddenSize; j++) {
                double sum = m_bf[j];
                // Wf * x
                for(int i=0; i<m_inputSize; i++) {
                    sum += features[i] * m_Wf[i*m_hiddenSize + j];
                }
                // Uf * h
                for(int k=0; k<m_hiddenSize; k++) {
                    sum += m_h[k] * m_Uf[k*m_hiddenSize + j];
                }
                f_gate[j] = Sigmoid(sum);
            }

            // 2. Candidate Hidden: h_tilde = Tanh(Wh*x + Uh*(f*h) + bh)
            for(int j=0; j<m_hiddenSize; j++) {
                double sum = m_bh[j];
                // Wh * x
                for(int i=0; i<m_inputSize; i++) {
                    sum += features[i] * m_Wh[i*m_hiddenSize + j];
                }
                // Uh * (f * h)
                for(int k=0; k<m_hiddenSize; k++) {
                    double gated_h = f_gate[k] * m_h[k]; // Element-wise
                    sum += gated_h * m_Uh[k*m_hiddenSize + j];
                }
                h_tilde[j] = Tanh(sum);
            }

            // 3. Update Hidden State: h = (1-f)*h + f*h_tilde
            // Note: Standard MGU is (1-f)*h + f*h_tilde OR (1-f)*h_tilde + f*h
            // Using variant: h_new = (1-f)*h_old + f*h_tilde
            for(int j=0; j<m_hiddenSize; j++) {
                m_h[j] = (1.0 - f_gate[j]) * m_h[j] + f_gate[j] * h_tilde[j];
            }
        }

        // --- Phase 2: Answer Refinement ---
        // y = Sigmoid(Wy * h + by)
        double output = 0;
        for(int j=0; j<m_outputSize; j++) {
            double sum = m_by[j];
            for(int i=0; i<m_hiddenSize; i++) {
                sum += m_h[i] * m_Wy[i*m_outputSize + j];
            }
            output = Sigmoid(sum);
            m_y[j] = output;
        }

        // Update confidence based on signal strength (deviation from 0.5)
        UpdateConfidence(output);

        return output;
    }

    // Simplified Training (Evolutionary / Hebbian-like)
    // Full BPTT is too heavy for MQL5 without matrix lib.
    // We update the last layer (Wy) using gradient descent,
    // and nudge internal weights (Wf, Wh) based on error signal.
    void Train(double &features[], double target, double learningRate) {
        double prediction = Forward(features);
        double error = target - prediction;

        // 1. Update Output Layer (Wy, by)
        // dL/dy * dy/dz = error * sigmoid_derivative
        double d_out = error * prediction * (1.0 - prediction);

        for(int j=0; j<m_outputSize; j++) {
             m_by[j] += learningRate * d_out;
             for(int i=0; i<m_hiddenSize; i++) {
                 // Update weight: delta = lr * error * input(h)
                 m_Wy[i*m_outputSize + j] += learningRate * d_out * m_h[i];
                 // Backprop signal to hidden layer (approximate)
                 // This is a "Feedback Alignment" approximation, robust for online learning
                 double d_hidden = d_out * m_Wy[i*m_outputSize + j] * (1.0 - m_h[i]*m_h[i]); // Tanh derivative approx

                 // Nudge internal weights slightly towards the gradient
                 // (Simplified plasticity, not full BPTT)
                 for(int k=0; k<m_inputSize; k++) {
                     // Hebbian-like update: correlated input x and hidden error d_hidden
                     double delta = learningRate * 0.1 * d_hidden * features[k];
                     m_Wf[k*m_hiddenSize + i] += delta;
                     m_Wh[k*m_hiddenSize + i] += delta;
                 }
             }
        }
    }

    void UpdateConfidence(double output) {
        // Higher confidence if output is close to 0 or 1
        double strength = 2.0 * MathAbs(output - 0.5);
        m_confidence = 0.95 * m_confidence + 0.05 * strength;
    }

    double GetConfidence() { return m_confidence; }

    void SaveState(int handle) {
        FileWriteArray(handle, m_Wf); FileWriteArray(handle, m_Uf); FileWriteArray(handle, m_bf);
        FileWriteArray(handle, m_Wh); FileWriteArray(handle, m_Uh); FileWriteArray(handle, m_bh);
        FileWriteArray(handle, m_Wy); FileWriteArray(handle, m_by);
        FileWriteArray(handle, m_h);
        FileWriteDouble(handle, m_confidence);
    }

    void LoadState(int handle) {
        FileReadArray(handle, m_Wf); FileReadArray(handle, m_Uf); FileReadArray(handle, m_bf);
        FileReadArray(handle, m_Wh); FileReadArray(handle, m_Uh); FileReadArray(handle, m_bh);
        FileReadArray(handle, m_Wy); FileReadArray(handle, m_by);
        FileReadArray(handle, m_h);
        m_confidence = FileReadDouble(handle);
    }
};

//+------------------------------------------------------------------+
//| Risk Assessment with outlier detection                          |
//+------------------------------------------------------------------+
class CRiskAssessor {
private:
    double m_fearLevel;
    double m_greedLevel;
    double m_marketVolatility;
    double m_maxDrawdownMemory;
    double m_volatilityHistory[];
    int    m_historyIndex;

    bool IsOutlier(double value, double mean, double stdDev) {
        return MathAbs(value - mean) > 3 * stdDev;
    }

public:
    CRiskAssessor() {
        m_fearLevel = 0.5;
        m_greedLevel = 0.5;
        m_marketVolatility = 0.0;
        m_maxDrawdownMemory = 0.0;
        m_historyIndex = 0;
        ArrayResize(m_volatilityHistory, 100);
        ArrayInitialize(m_volatilityHistory, 0);
    }

    double EvaluateRisk(double currentDrawdown, double volatility, double profitPotential) {
        if(!MathIsValidNumber(currentDrawdown) || currentDrawdown < 0) currentDrawdown = 0;
        if(!MathIsValidNumber(volatility) || volatility < 0) volatility = 0;
        if(!MathIsValidNumber(profitPotential)) profitPotential = 0.5;

        currentDrawdown = MathMin(1.0, currentDrawdown);
        volatility = MathMin(1.0, volatility);
        profitPotential = MathMax(0, MathMin(1, profitPotential));

        m_volatilityHistory[m_historyIndex] = volatility;
        m_historyIndex = (m_historyIndex + 1) % ArraySize(m_volatilityHistory);

        double volMean = 0, volStdDev = 0;
        for(int i = 0; i < ArraySize(m_volatilityHistory); i++) {
            volMean += m_volatilityHistory[i];
        }
        volMean /= ArraySize(m_volatilityHistory);

        for(int i = 0; i < ArraySize(m_volatilityHistory); i++) {
            volStdDev += MathPow(m_volatilityHistory[i] - volMean, 2);
        }
        volStdDev = MathSqrt(volStdDev / ArraySize(m_volatilityHistory));

        if(IsOutlier(volatility, volMean, volStdDev)) {
            Print("WARNING: Volatility outlier detected: ", volatility);
            volatility = volMean + 2 * volStdDev;
        }

        m_marketVolatility = volatility;

        if(currentDrawdown > m_maxDrawdownMemory) {
            m_maxDrawdownMemory = currentDrawdown;
            m_fearLevel = MathMin(m_fearLevel + 0.1, 0.9);
        } else {
            m_fearLevel *= 0.98;
            m_fearLevel = MathMax(0.1, m_fearLevel);
        }

        m_greedLevel = profitPotential * (1 - m_fearLevel * 0.5);
        m_greedLevel = MathMax(0.1, MathMin(0.8, m_greedLevel));

        double riskScore = (1 - m_fearLevel) * 0.7 + (1 - volatility) * 0.3;

        double greedModifier = 1 + (m_greedLevel - 0.5) * 0.2;
        greedModifier = MathMax(0.5, MathMin(1.5, greedModifier));
        riskScore *= greedModifier;

        return MathMax(0.1, MathMin(1.0, riskScore));
    }

    void ProcessTradeResult(double profit, double drawdown) {
        if(!MathIsValidNumber(profit)) profit = 0;
        if(!MathIsValidNumber(drawdown) || drawdown < 0) drawdown = 0;

        if(profit > 0) {
            m_fearLevel *= 0.95;
            m_greedLevel = MathMin(m_greedLevel + 0.02, 0.8);
        } else {
            m_fearLevel = MathMin(m_fearLevel + 0.05, 0.9);
            m_greedLevel *= 0.9;
        }

        m_fearLevel = MathMax(0.1, MathMin(0.9, m_fearLevel));
        m_greedLevel = MathMax(0.1, MathMin(0.8, m_greedLevel));
    }

    void SaveState(int handle) {
        FileWriteDouble(handle, m_fearLevel);
        FileWriteDouble(handle, m_greedLevel);
        FileWriteDouble(handle, m_marketVolatility);
        FileWriteDouble(handle, m_maxDrawdownMemory);
    }

    void LoadState(int handle) {
        m_fearLevel = FileReadDouble(handle);
        m_greedLevel = FileReadDouble(handle);
        m_marketVolatility = FileReadDouble(handle);
        m_maxDrawdownMemory = FileReadDouble(handle);
    }
};

//+------------------------------------------------------------------+
//| Decision Module with ensemble voting                            |
//+------------------------------------------------------------------+
class CDecisionMaker {
private:
    double m_decisionThreshold;
    double m_decisionHistory[];
    int    m_correctDecisions;
    int    m_totalDecisions;
    double m_voteWeights[3];

    double SafeDivide(double num, double denom) {
        return (MathAbs(denom) < 0.0000001) ? 0 : num / denom;
    }

public:
    CDecisionMaker() {
        m_decisionThreshold = 0.6;
        m_correctDecisions = 0;
        m_totalDecisions = 0;
        ArrayResize(m_decisionHistory, 1000);
        m_voteWeights[0] = 0.4;
        m_voteWeights[1] = 0.3;
        m_voteWeights[2] = 0.3;
    }

    int MakeDecision(double patternScore, double riskScore, double marketSentiment) {
        patternScore = MathMax(0, MathMin(1, patternScore));
        riskScore = MathMax(0, MathMin(1, riskScore));
        marketSentiment = MathMax(0, MathMin(1, marketSentiment));

        double decision = patternScore * m_voteWeights[0] +
                         riskScore * m_voteWeights[1] +
                         marketSentiment * m_voteWeights[2];

        double weightSum = m_voteWeights[0] + m_voteWeights[1] + m_voteWeights[2];
        if(MathAbs(weightSum - 1.0) > 0.01) {
            for(int i = 0; i < 3; i++) {
                m_voteWeights[i] /= weightSum;
            }
        }

        if(m_totalDecisions > 20) {
            double accuracy = SafeDivide(m_correctDecisions, m_totalDecisions);

            if(accuracy < 0.45) {
                m_decisionThreshold = MathMin(m_decisionThreshold + 0.02, 0.8);
            } else if(accuracy > 0.60) {
                m_decisionThreshold = MathMax(m_decisionThreshold - 0.01, 0.5);
            }
        }

        int slot = m_totalDecisions % ArraySize(m_decisionHistory);
        m_decisionHistory[slot] = decision;
        m_totalDecisions++;

        if(decision > m_decisionThreshold) {
            return (patternScore > 0.5) ? 1 : -1;
        }

        return 0;
    }

    void RecordOutcome(bool success) {
        if(success) m_correctDecisions++;

        if(m_totalDecisions > 100) {
            double accuracy = SafeDivide(m_correctDecisions, m_totalDecisions);

            if(accuracy > 0.55) {
                m_voteWeights[0] = MathMin(m_voteWeights[0] * 1.05, 0.6);
            }
        }
    }

    void SaveState(int handle) {
        FileWriteDouble(handle, m_decisionThreshold);
        FileWriteInteger(handle, m_correctDecisions);
        FileWriteInteger(handle, m_totalDecisions);
        for(int i = 0; i < 3; i++) {
            FileWriteDouble(handle, m_voteWeights[i]);
        }
    }

    void LoadState(int handle) {
        m_decisionThreshold = FileReadDouble(handle);
        m_correctDecisions = FileReadInteger(handle);
        m_totalDecisions = FileReadInteger(handle);
        for(int i = 0; i < 3; i++) {
            m_voteWeights[i] = FileReadDouble(handle);
        }
    }
};

//+------------------------------------------------------------------+
//| Global Brain Instance                                           |
//+------------------------------------------------------------------+
CMetaLearner* g_metaLearner = NULL;
CTinyRecursiveModel* g_trm = NULL;
CRiskAssessor* g_riskAssessor = NULL;
CDecisionMaker* g_decisionMaker = NULL;
TradeMemory g_memoryBank[];
int g_memoryCount = 0;

//+------------------------------------------------------------------+
//| Initialize Neuroplastic Brain                                   |
//+------------------------------------------------------------------+
bool InitializeNeuroplasticBrain() {
    g_metaLearner = new CMetaLearner();
    g_trm = new CTinyRecursiveModel();
    g_riskAssessor = new CRiskAssessor();
    g_decisionMaker = new CDecisionMaker();

    ArrayResize(g_memoryBank, MAX_MEMORY_SIZE);
    g_memoryCount = 0;

    for(int i = 0; i < MAX_MEMORY_SIZE; i++) {
        g_memoryBank[i].Initialize();
    }

    bool success = (g_metaLearner != NULL &&
                   g_patternRecognizer != NULL &&
                   g_riskAssessor != NULL &&
                   g_decisionMaker != NULL);

    if(success) {
        Print("Neuroplastic Brain initialized successfully");
    }

    return success;
}

//+------------------------------------------------------------------+
//| Get Brain Signal                                                |
//+------------------------------------------------------------------+
int GetBrainSignal(double &features[], double currentDrawdown) {
    if(g_trm == NULL || g_riskAssessor == NULL || g_decisionMaker == NULL) {
        return 0;
    }

    double patternScore = g_trm.Forward(features);

    double volatility = (ArraySize(features) > 1) ? MathAbs(features[1]) : 0.5;
    double profitPotential = patternScore;
    double riskScore = g_riskAssessor.EvaluateRisk(currentDrawdown, volatility, profitPotential);

    double marketSentiment = patternScore;

    return g_decisionMaker.MakeDecision(patternScore, riskScore, marketSentiment);
}

//+------------------------------------------------------------------+
//| Get Brain Confidence                                            |
//+------------------------------------------------------------------+
double GetBrainConfidence() {
    if(g_trm == NULL) return 0.5;
    return g_trm.GetConfidence();
}

//+------------------------------------------------------------------+
//| Teach Brain from Trade Result                                  |
//+------------------------------------------------------------------+
void TeachBrain(datetime entryTime, double entryPrice, double exitPrice,
                double volume, int direction, double profit, double maxDrawdown,
                double &entryFeatures[]) { // Zenith: Added features argument

    if(g_memoryCount >= MAX_MEMORY_SIZE) {
        for(int i = 0; i < MAX_MEMORY_SIZE - 1; i++) {
            g_memoryBank[i] = g_memoryBank[i + 1];
        }
        g_memoryCount = MAX_MEMORY_SIZE - 1;
    }

    g_memoryBank[g_memoryCount].timestamp = entryTime;
    g_memoryBank[g_memoryCount].entryPrice = entryPrice;
    g_memoryBank[g_memoryCount].exitPrice = exitPrice;
    g_memoryBank[g_memoryCount].volume = volume;
    g_memoryBank[g_memoryCount].direction = direction;
    g_memoryBank[g_memoryCount].profit = profit;
    g_memoryBank[g_memoryCount].drawdown = maxDrawdown;

    // Copy features to memory
    if(ArraySize(entryFeatures) == 20) {
        ArrayCopy(g_memoryBank[g_memoryCount].features, entryFeatures);
    }

    g_memoryBank[g_memoryCount].checksum = g_memoryBank[g_memoryCount].CalculateChecksum();
    g_memoryCount++;

    if(g_metaLearner != NULL && g_riskAssessor != NULL) {
        double performance = (profit > 0) ? 1.0 : 0.0;
        double learningRate = g_metaLearner.OptimizeLearningRate(performance);

        // Zenith: Online Training Trigger
        if(g_trm != NULL && ArraySize(entryFeatures) > 0) {
            // Target: 1.0 for Buy, 0.0 for Sell
            // If Buy & Profit -> Target 1.0. If Buy & Loss -> Target 0.0
            // If Sell & Profit -> Target 0.0. If Sell & Loss -> Target 1.0
            double target = (direction > 0) ? (profit > 0 ? 1.0 : 0.0) : (profit > 0 ? 0.0 : 1.0);

            // Train the TRM immediately (Online Learning)
            g_trm.Train(entryFeatures, target, learningRate);
        }

        g_riskAssessor.ProcessTradeResult(profit, maxDrawdown);

        if(g_decisionMaker != NULL) {
            g_decisionMaker.RecordOutcome(profit > 0);
        }
    }
}

//+------------------------------------------------------------------+
//| Get Brain Diagnostics                                           |
//+------------------------------------------------------------------+
string GetBrainDiagnostics() {
    string report = "=== Brain Diagnostics (Zenith TRM) ===\n";

    if(g_metaLearner != NULL) {
        report += StringFormat("Learning Rate: %.6f\n", g_metaLearner.GetLearningRate());
    }

    if(g_trm != NULL) {
        report += StringFormat("TRM Confidence: %.2f%%\n",
                              g_trm.GetConfidence() * 100);
    }

    report += StringFormat("Memory Banks: %d/%d\n", g_memoryCount, MAX_MEMORY_SIZE);

    return report;
}

//+------------------------------------------------------------------+
//| Cleanup Brain                                                   |
//+------------------------------------------------------------------+
void CleanupBrain() {
    if(g_metaLearner != NULL) {
        delete g_metaLearner;
        g_metaLearner = NULL;
    }

    if(g_trm != NULL) {
        delete g_trm;
        g_trm = NULL;
    }

    if(g_riskAssessor != NULL) {
        delete g_riskAssessor;
        g_riskAssessor = NULL;
    }

    if(g_decisionMaker != NULL) {
        delete g_decisionMaker;
        g_decisionMaker = NULL;
    }

    ArrayFree(g_memoryBank);
    g_memoryCount = 0;
}

//+------------------------------------------------------------------+
