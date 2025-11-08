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
//| Pattern Recognition with validation                             |
//+------------------------------------------------------------------+
class CPatternRecognizer {
private:
    double m_weights[];
    double m_bias;
    double m_confidence;
    int    m_patternsRecognized;
    double m_lastFeatures[];
    double m_cachedActivation;
    bool   m_cacheValid;

    bool ValidateFeatures(double &features[]) {
        int size = ArraySize(features);
        if(size == 0) return false;

        for(int i = 0; i < size; i++) {
            if(!MathIsValidNumber(features[i])) {
                Print("WARNING: Invalid feature at index ", i);
                features[i] = 0;
            }
        }
        return true;
    }

    bool FeaturesChanged(double &features[]) {
        int size = ArraySize(features);
        if(size != ArraySize(m_lastFeatures)) return true;

        for(int i = 0; i < size; i++) {
            if(MathAbs(features[i] - m_lastFeatures[i]) > 0.00001) {
                return true;
            }
        }
        return false;
    }

public:
    CPatternRecognizer() {
        ArrayResize(m_weights, 20);
        ArrayResize(m_lastFeatures, 20);
        InitializeWeights();
        m_bias = 0.0;
        m_confidence = 0.5;
        m_patternsRecognized = 0;
        m_cacheValid = false;
    }

    void InitializeWeights() {
        for(int i = 0; i < ArraySize(m_weights); i++) {
            m_weights[i] = (MathRand() / 32768.0 - 0.5) * 0.1;
        }
    }

    double RecognizePattern(double &features[]) {
        if(!ValidateFeatures(features)) {
            return 0.5;
        }

        if(m_cacheValid && !FeaturesChanged(features)) {
            return m_cachedActivation;
        }

        double activation = m_bias;
        int size = MathMin(ArraySize(features), ArraySize(m_weights));

        for(int i = 0; i < size; i++) {
            activation += features[i] * m_weights[i];
        }

        activation = MathMax(-MOMENTUM_CLAMP, MathMin(MOMENTUM_CLAMP, activation));

        double output = 1.0 / (1.0 + MathExp(-activation * m_confidence));

        ArrayCopy(m_lastFeatures, features, 0, 0, size);
        m_cachedActivation = output;
        m_cacheValid = true;

        m_patternsRecognized++;
        UpdateConfidence(output);

        return output;
    }

    void Learn(double &features[], double target, double learningRate) {
        if(!ValidateFeatures(features)) return;

        target = MathMax(0, MathMin(1, target));
        learningRate = MathMax(MIN_LEARNING_RATE, MathMin(MAX_LEARNING_RATE, learningRate));

        double prediction = RecognizePattern(features);
        double error = target - prediction;

        error = MathMax(-1, MathMin(1, error));

        int size = MathMin(ArraySize(features), ArraySize(m_weights));
        double gradientMagnitude = 0;

        for(int i = 0; i < size; i++) {
            double gradient = error * features[i] * prediction * (1 - prediction);
            gradientMagnitude += gradient * gradient;
        }

        gradientMagnitude = MathSqrt(gradientMagnitude);
        double gradientScale = gradientMagnitude > 1.0 ? 1.0 / gradientMagnitude : 1.0;

        for(int i = 0; i < size; i++) {
            double gradient = error * features[i] * prediction * (1 - prediction);
            m_weights[i] += learningRate * gradient * gradientScale;
            m_weights[i] = MathMax(-1, MathMin(1, m_weights[i]));
        }

        m_bias += learningRate * error * prediction * (1 - prediction) * gradientScale;
        m_bias = MathMax(-1, MathMin(1, m_bias));

        m_cacheValid = false;
    }

    void UpdateConfidence(double accuracy) {
        accuracy = MathMax(0, MathMin(1, accuracy));
        m_confidence = m_confidence * 0.95 + accuracy * 0.05;
        m_confidence = MathMax(0.1, MathMin(1.0, m_confidence));
    }

    double GetConfidence() { return m_confidence; }

    void SaveState(int handle) {
        FileWriteInteger(handle, ArraySize(m_weights));
        for(int i = 0; i < ArraySize(m_weights); i++) {
            FileWriteDouble(handle, m_weights[i]);
        }
        FileWriteDouble(handle, m_bias);
        FileWriteDouble(handle, m_confidence);
    }

    void LoadState(int handle) {
        int size = FileReadInteger(handle);
        ArrayResize(m_weights, size);
        for(int i = 0; i < size; i++) {
            m_weights[i] = FileReadDouble(handle);
        }
        m_bias = FileReadDouble(handle);
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
CPatternRecognizer* g_patternRecognizer = NULL;
CRiskAssessor* g_riskAssessor = NULL;
CDecisionMaker* g_decisionMaker = NULL;
TradeMemory g_memoryBank[];
int g_memoryCount = 0;

//+------------------------------------------------------------------+
//| Initialize Neuroplastic Brain                                   |
//+------------------------------------------------------------------+
bool InitializeNeuroplasticBrain() {
    g_metaLearner = new CMetaLearner();
    g_patternRecognizer = new CPatternRecognizer();
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
    if(g_patternRecognizer == NULL || g_riskAssessor == NULL || g_decisionMaker == NULL) {
        return 0;
    }

    double patternScore = g_patternRecognizer.RecognizePattern(features);

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
    if(g_patternRecognizer == NULL) return 0.5;
    return g_patternRecognizer.GetConfidence();
}

//+------------------------------------------------------------------+
//| Teach Brain from Trade Result                                  |
//+------------------------------------------------------------------+
void TeachBrain(datetime entryTime, double entryPrice, double exitPrice,
                double volume, int direction, double profit, double maxDrawdown) {

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
    g_memoryBank[g_memoryCount].checksum = g_memoryBank[g_memoryCount].CalculateChecksum();
    g_memoryCount++;

    if(g_metaLearner != NULL && g_patternRecognizer != NULL && g_riskAssessor != NULL) {
        double performance = (profit > 0) ? 1.0 : 0.0;
        double learningRate = g_metaLearner.OptimizeLearningRate(performance);

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
    string report = "=== Brain Diagnostics ===\n";

    if(g_metaLearner != NULL) {
        report += StringFormat("Learning Rate: %.6f\n", g_metaLearner.GetLearningRate());
    }

    if(g_patternRecognizer != NULL) {
        report += StringFormat("Pattern Confidence: %.2f%%\n",
                              g_patternRecognizer.GetConfidence() * 100);
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

    if(g_patternRecognizer != NULL) {
        delete g_patternRecognizer;
        g_patternRecognizer = NULL;
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
