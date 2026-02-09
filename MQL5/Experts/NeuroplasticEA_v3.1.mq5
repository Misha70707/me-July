//+------------------------------------------------------------------+
//|                                        NeuroplasticEA_v3.1.mq5  |
//|                        Enhanced Neuroplastic Trading System     |
//|                  Bio-Informed Quantitative Architecture v3.1    |
//|                     ZENITH PROTOCOL OPTIMIZED BUILD             |
//+------------------------------------------------------------------+
#property copyright "Aidan Vale - Bio-Informed Trading Systems"
#property version   "3.10"
#property strict

#include <Trade\Trade.mqh>
#include <Math\Stat\Math.mqh>

//--- Market Regime Enumeration
enum MARKET_REGIME {
    REGIME_TRENDING_BULL,
    REGIME_TRENDING_BEAR,
    REGIME_RANGING,
    REGIME_VOLATILE,
    REGIME_QUIET
};

//--- Neuroplasticity Constants
#define HEBBIAN_RATE          0.01
#define SYNAPTIC_DECAY        0.995
#define PRUNING_THRESHOLD     0.1
#define NEUROGENESIS_RATE     0.001
#define REFRACTORY_MS         5000

//--- Enhanced Neural Constants
#define METAPLASTICITY_RATE   0.05
#define STRESS_THRESHOLD      0.7
#define REGIME_WINDOW         100
#define KELLY_FRACTION        0.25
#define MIN_TRADES_FOR_KELLY  30

//+------------------------------------------------------------------+
//| Trade Performance Tracker - Calculates real win rate           |
//+------------------------------------------------------------------+
class TradePerformanceTracker {
private:
    struct TradeRecord {
        datetime closeTime;
        double profit;
        double size;
        MARKET_REGIME regime;
    };

    TradeRecord m_history[];
    int m_historySize;
    int m_historyIndex;

public:
    TradePerformanceTracker(int maxHistory = 500) {
        m_historySize = maxHistory;
        ArrayResize(m_history, m_historySize);
        m_historyIndex = 0;
        // Pre-initialize to avoid checks later
        for(int i=0; i<maxHistory; i++) m_history[i].closeTime = 0;
    }

    //--- Record closed trade
    void RecordTrade(double profit, double size, MARKET_REGIME regime) {
        m_history[m_historyIndex].closeTime = TimeCurrent();
        m_history[m_historyIndex].profit = profit;
        m_history[m_historyIndex].size = size;
        m_history[m_historyIndex].regime = regime;

        m_historyIndex = (m_historyIndex + 1) % m_historySize;
    }

    //--- Calculate actual win rate
    double GetWinRate(MARKET_REGIME regime = -1) {
        int wins = 0;
        int total = 0;

        for(int i = 0; i < m_historySize; i++) {
            if(m_history[i].closeTime == 0) continue;
            if(regime >= 0 && m_history[i].regime != regime) continue;

            total++;
            if(m_history[i].profit > 0) wins++;
        }

        return total > 0 ? (double)wins / total : 0.55;
    }

    //--- Calculate average win
    double GetAvgWin() {
        double sum = 0.0;
        int count = 0;

        for(int i = 0; i < m_historySize; i++) {
            if(m_history[i].closeTime == 0) continue;
            if(m_history[i].profit > 0) {
                sum += m_history[i].profit;
                count++;
            }
        }

        return count > 0 ? sum / count : 100.0;
    }

    //--- Calculate average loss
    double GetAvgLoss() {
        double sum = 0.0;
        int count = 0;

        for(int i = 0; i < m_historySize; i++) {
            if(m_history[i].closeTime == 0) continue;
            if(m_history[i].profit < 0) {
                sum += MathAbs(m_history[i].profit);
                count++;
            }
        }

        return count > 0 ? sum / count : 50.0;
    }

    //--- Get total trade count
    int GetTradeCount() {
        int count = 0;
        for(int i = 0; i < m_historySize; i++) {
            if(m_history[i].closeTime != 0) count++;
        }
        return count;
    }
};

//+------------------------------------------------------------------+
//| Base NeuroplasticBrain Class                                    |
//+------------------------------------------------------------------+
class NeuroplasticBrain {
protected:
    double m_globalPlasticity;
    double m_stressLevel;
    MARKET_REGIME m_marketRegime;
    CTrade m_trade;
    TradePerformanceTracker* m_perfTracker;

public:
    NeuroplasticBrain() {
        m_globalPlasticity = 1.0;
        m_stressLevel = 0.0;
        m_marketRegime = REGIME_RANGING;
        m_perfTracker = new TradePerformanceTracker();
    }

    virtual ~NeuroplasticBrain() {
        if(m_perfTracker != NULL) delete m_perfTracker;
    }

    virtual void Process() {}
    virtual void RewardLearning(double profit) {}

    MARKET_REGIME GetCurrentRegime() { return m_marketRegime; }
    double GetStressLevel() { return m_stressLevel; }
    double GetPlasticity() { return m_globalPlasticity; }
    TradePerformanceTracker* GetPerfTracker() { return m_perfTracker; }
};

//+------------------------------------------------------------------+
//| Momentum Flow Oscillator - OPTIMIZED: Persistent handles       |
//+------------------------------------------------------------------+
class MomentumFlowOscillator {
private:
    double m_momentum[];
    int m_periods[];
    double m_weights[];
    double m_flowStrength;
    int m_handles[];  // Persistent indicator handles
    double m_maBuffer[]; // Pre-allocated buffer for calculations

public:
    MomentumFlowOscillator() {
        ArrayResize(m_momentum, 3);
        ArrayResize(m_periods, 3);
        ArrayResize(m_weights, 3);
        ArrayResize(m_handles, 3);
        ArrayResize(m_maBuffer, 2); // Only need 2 values
        ArraySetAsSeries(m_maBuffer, true);

        m_periods[0] = 5;   // Fast
        m_periods[1] = 21;  // Medium
        m_periods[2] = 89;  // Slow

        m_weights[0] = 0.5;
        m_weights[1] = 0.3;
        m_weights[2] = 0.2;

        m_flowStrength = 0.0;

        // Create persistent handles
        for(int i = 0; i < 3; i++) {
            m_handles[i] = iMA(_Symbol, PERIOD_M5, m_periods[i], 0, MODE_EMA, PRICE_CLOSE);
        }
    }

    ~MomentumFlowOscillator() {
        for(int i = 0; i < 3; i++) {
            if(m_handles[i] != INVALID_HANDLE) {
                IndicatorRelease(m_handles[i]);
            }
        }
    }

    //--- Calculate multi-timeframe momentum flow
    double CalculateFlow() {
        for(int i = 0; i < 3; i++) {
            if(m_handles[i] == INVALID_HANDLE) {
                m_momentum[i] = 0.0;
                continue;
            }

            // Reuse member buffer, no reallocation
            if(CopyBuffer(m_handles[i], 0, 0, 2, m_maBuffer) >= 2 && m_maBuffer[1] != 0) {
                m_momentum[i] = (m_maBuffer[0] - m_maBuffer[1]) / m_maBuffer[1] * 100;
            } else {
                m_momentum[i] = 0.0;
            }
        }

        // Weighted momentum aggregation
        m_flowStrength = 0.0;
        for(int i = 0; i < 3; i++) {
            m_flowStrength += m_momentum[i] * m_weights[i];
        }

        return MathTanh(m_flowStrength / 10.0);
    }

    //--- Hebbian weight update: strengthen weights that correlate with profit
    void UpdateWeights(double reward) {
        if(MathAbs(m_flowStrength) < 0.01) return;

        double totalWeight = 0.0;
        for(int i = 0; i < 3; i++) {
            double hebbian = HEBBIAN_RATE * reward * m_momentum[i] * m_flowStrength;
            m_weights[i] += hebbian;
            m_weights[i] = MathMax(0.0, m_weights[i]);  // No negative weights
            totalWeight += m_weights[i];
        }

        // Normalize
        if(totalWeight > 0) {
            for(int i = 0; i < 3; i++) {
                m_weights[i] /= totalWeight;
            }
        }
    }

    //--- Synaptic pruning: remove weak connections
    void PruneWeights() {
        for(int i = 0; i < 3; i++) {
            if(m_weights[i] < PRUNING_THRESHOLD) {
                m_weights[i] = 0.0;
            }
            m_weights[i] *= SYNAPTIC_DECAY;
        }

        // Renormalize
        double total = 0.0;
        for(int i = 0; i < 3; i++) total += m_weights[i];

        if(total > 0) {
            for(int i = 0; i < 3; i++) {
                m_weights[i] /= total;
            }
        } else {
            // Reset to default if all pruned
            m_weights[0] = 0.5;
            m_weights[1] = 0.3;
            m_weights[2] = 0.2;
        }
    }

    bool CheckDivergence() {
        return (m_momentum[0] * m_momentum[2] < 0);
    }

    double GetFlowStrength() { return m_flowStrength; }
    void GetWeights(double &weights[]) { ArrayCopy(weights, m_weights); }
};

//+------------------------------------------------------------------+
//| Market Structure Analyzer - OPTIMIZED: Pre-allocated buffer     |
//+------------------------------------------------------------------+
class MarketStructureAnalyzer {
private:
    struct PriceZone {
        double price;
        double strength;
        datetime lastTouch;
        bool isSupport;
    };

    PriceZone m_zones[];
    int m_zoneCount; // Replaces dynamic resizing
    int m_maxZones;
    double m_currentBias;

    bool IsSwingHigh(int shift) {
        double high = iHigh(_Symbol, PERIOD_M5, shift);
        for(int i = 1; i <= 3; i++) {
            if(iHigh(_Symbol, PERIOD_M5, shift - i) >= high ||
               iHigh(_Symbol, PERIOD_M5, shift + i) >= high) {
                return false;
            }
        }
        return true;
    }

    bool IsSwingLow(int shift) {
        double low = iLow(_Symbol, PERIOD_M5, shift);
        for(int i = 1; i <= 3; i++) {
            if(iLow(_Symbol, PERIOD_M5, shift - i) <= low ||
               iLow(_Symbol, PERIOD_M5, shift + i) <= low) {
                return false;
            }
        }
        return true;
    }

public:
    MarketStructureAnalyzer() {
        m_maxZones = 200;
        ArrayResize(m_zones, m_maxZones);
        m_zoneCount = 0;
        m_currentBias = 0.0;
    }

    void AnalyzeStructure() {
        m_zoneCount = 0; // Reset count, reuse buffer

        for(int i = 10; i < 100; i++) {
            if(IsSwingHigh(i)) {
                AddZone(iHigh(_Symbol, PERIOD_M5, i), false);
            }
            if(IsSwingLow(i)) {
                AddZone(iLow(_Symbol, PERIOD_M5, i), true);
            }
        }

        CalculateBias();
    }

    void AddZone(double price, bool isSupport) {
        // Check existing zones (only up to valid count)
        for(int i = 0; i < m_zoneCount; i++) {
            if(MathAbs(m_zones[i].price - price) < _Point * 10) {
                m_zones[i].strength += 1.0;
                m_zones[i].lastTouch = TimeCurrent();
                return;
            }
        }

        if (m_zoneCount < m_maxZones) {
            m_zones[m_zoneCount].price = price;
            m_zones[m_zoneCount].strength = 1.0;
            m_zones[m_zoneCount].lastTouch = TimeCurrent();
            m_zones[m_zoneCount].isSupport = isSupport;
            m_zoneCount++;
        }
    }

    void CalculateBias() {
        double currentPrice = iClose(_Symbol, PERIOD_M5, 0);
        double supportSum = 0.0;
        double resistanceSum = 0.0;

        for(int i = 0; i < m_zoneCount; i++) {
            double distance = MathAbs(currentPrice - m_zones[i].price);
            double weight = m_zones[i].strength / (1.0 + distance / _Point);

            if(m_zones[i].isSupport && m_zones[i].price < currentPrice) {
                supportSum += weight;
            } else if(!m_zones[i].isSupport && m_zones[i].price > currentPrice) {
                resistanceSum += weight;
            }
        }

        double total = supportSum + resistanceSum;
        if(total > 0) {
            m_currentBias = (supportSum - resistanceSum) / total;
        } else {
            m_currentBias = 0.0;
        }
    }

    double GetStructureBias() {
        if(m_zoneCount == 0) return 0.0;

        double supportStrength = 0.0;
        double resistanceStrength = 0.0;

        for(int i = 0; i < m_zoneCount; i++) {
            if(m_zones[i].isSupport) {
                supportStrength += m_zones[i].strength;
            } else {
                resistanceStrength += m_zones[i].strength;
            }
        }

        double totalStrength = supportStrength + resistanceStrength;
        if(totalStrength > 0) {
            return (supportStrength - resistanceStrength) / totalStrength;
        }

        return 0.0;
    }

    double GetBias() { return m_currentBias; }
};

//+------------------------------------------------------------------+
//| Volume Profile Analyzer                                         |
//+------------------------------------------------------------------+
class VolumeProfileAnalyzer {
private:
    struct VolumeNode {
        double price;
        long volume;
        double delta;
    };

    VolumeNode m_profile[];
    double m_pocPrice;
    double m_imbalance;

public:
    VolumeProfileAnalyzer() {
        ArrayResize(m_profile, 0);
        m_pocPrice = 0.0;
        m_imbalance = 0.0;
    }

    void BuildProfile(int periods = 50) {
        // Optimization: This logic involves a loop of 50 and potentially heavy calculations.
        // It is called from Process() which we will gate with NewBar.
        ArrayResize(m_profile, 0); // Reset for fresh build

        double priceStep = _Point * 10;
        double minPrice = DBL_MAX;
        double maxPrice = -DBL_MAX;

        for(int i = 0; i < periods; i++) {
            double high = iHigh(_Symbol, PERIOD_M5, i);
            double low = iLow(_Symbol, PERIOD_M5, i);
            if(high > maxPrice) maxPrice = high;
            if(low < minPrice) minPrice = low;
        }

        int levels = (int)((maxPrice - minPrice) / priceStep) + 1;
        if(levels <= 0 || levels > 1000) return;

        ArrayResize(m_profile, levels);

        for(int i = 0; i < levels; i++) {
            m_profile[i].price = minPrice + i * priceStep;
            m_profile[i].volume = 0;
            m_profile[i].delta = 0.0;
        }

        for(int i = 0; i < periods; i++) {
            double high = iHigh(_Symbol, PERIOD_M5, i);
            double low = iLow(_Symbol, PERIOD_M5, i);
            double close = iClose(_Symbol, PERIOD_M5, i);
            double open = iOpen(_Symbol, PERIOD_M5, i);
            long vol = iVolume(_Symbol, PERIOD_M5, i);

            int startLevel = (int)((low - minPrice) / priceStep);
            int endLevel = (int)((high - minPrice) / priceStep);

            if(startLevel >= 0 && endLevel < levels && endLevel >= startLevel) {
                int range = endLevel - startLevel + 1;
                for(int j = startLevel; j <= endLevel; j++) {
                    m_profile[j].volume += vol / range;
                    if(close > open) {
                        m_profile[j].delta += vol / range * 0.6;
                    } else {
                        m_profile[j].delta -= vol / range * 0.6;
                    }
                }
            }
        }

        FindPOC();
        CalculateImbalance();
    }

    void FindPOC() {
        long maxVolume = 0;
        for(int i = 0; i < ArraySize(m_profile); i++) {
            if(m_profile[i].volume > maxVolume) {
                maxVolume = m_profile[i].volume;
                m_pocPrice = m_profile[i].price;
            }
        }
    }

    void CalculateImbalance() {
        double buyVolume = 0.0;
        double sellVolume = 0.0;

        for(int i = 0; i < ArraySize(m_profile); i++) {
            if(m_profile[i].delta > 0) {
                buyVolume += m_profile[i].delta;
            } else {
                sellVolume += MathAbs(m_profile[i].delta);
            }
        }

        double total = buyVolume + sellVolume;
        if(total > 0) {
            m_imbalance = (buyVolume - sellVolume) / total;
        } else {
            m_imbalance = 0.0;
        }
    }

    double GetPOC() { return m_pocPrice; }
    double GetImbalance() { return m_imbalance; }
};

//+------------------------------------------------------------------+
//| Position Manager - OPTIMIZED: Persistent ATR handle             |
//+------------------------------------------------------------------+
class PositionManager {
private:
    CTrade m_trade;
    double m_atrMultiplierSL;
    double m_atrMultiplierTP;
    int    m_atrHandle;
    double m_atrBuffer[];
    double m_currentATR;

public:
    PositionManager() {
        m_atrMultiplierSL = 2.0;
        m_atrMultiplierTP = 3.0;
        m_atrHandle = iATR(_Symbol, PERIOD_M5, 14);
        ArrayResize(m_atrBuffer, 1);
        ArraySetAsSeries(m_atrBuffer, true);
        m_currentATR = 0.0;
    }

    ~PositionManager() {
        if(m_atrHandle != INVALID_HANDLE) IndicatorRelease(m_atrHandle);
    }

    // Call once per tick to update cache
    void UpdateATR() {
        if(m_atrHandle != INVALID_HANDLE) {
            if(CopyBuffer(m_atrHandle, 0, 0, 1, m_atrBuffer) > 0) {
                m_currentATR = m_atrBuffer[0];
            }
        }
    }

    //--- Open position with risk management
    bool OpenPosition(double signal, double lotSize, MARKET_REGIME regime) {
        if(m_currentATR <= 0) UpdateATR();
        if(m_currentATR <= 0) return false; // Safety check

        double currentPrice = signal > 0 ? SymbolInfoDouble(_Symbol, SYMBOL_ASK) : SymbolInfoDouble(_Symbol, SYMBOL_BID);
        double sl = 0.0;
        double tp = 0.0;

        // Regime-adaptive SL/TP
        double slMultiplier = m_atrMultiplierSL;
        double tpMultiplier = m_atrMultiplierTP;

        if(regime == REGIME_VOLATILE) {
            slMultiplier *= 1.5;
            tpMultiplier *= 1.2;
        } else if(regime == REGIME_QUIET) {
            slMultiplier *= 0.7;
            tpMultiplier *= 0.8;
        }

        if(signal > 0) {
            sl = currentPrice - m_currentATR * slMultiplier;
            tp = currentPrice + m_currentATR * tpMultiplier;
            return m_trade.Buy(lotSize, _Symbol, 0, sl, tp);
        } else {
            sl = currentPrice + m_currentATR * slMultiplier;
            tp = currentPrice - m_currentATR * tpMultiplier;
            return m_trade.Sell(lotSize, _Symbol, 0, sl, tp);
        }
    }

    //--- Manage trailing stop
    void ManagePositions() {
        if(m_currentATR <= 0) UpdateATR();
        if(m_currentATR <= 0) return;

        double trailDistance = m_currentATR * 1.5;

        for(int i = PositionsTotal() - 1; i >= 0; i--) {
            ulong ticket = PositionGetTicket(i);
            if(ticket <= 0) continue;

            if(PositionGetString(POSITION_SYMBOL) != _Symbol) continue;

            double currentPrice = PositionGetDouble(POSITION_PRICE_CURRENT);
            double sl = PositionGetDouble(POSITION_SL);
            double tp = PositionGetDouble(POSITION_TP);

            ENUM_POSITION_TYPE type = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);

            if(type == POSITION_TYPE_BUY) {
                double newSL = currentPrice - trailDistance;
                if(newSL > sl && newSL < currentPrice) {
                    m_trade.PositionModify(ticket, newSL, tp);
                }
            } else {
                double newSL = currentPrice + trailDistance;
                if(newSL < sl && newSL > currentPrice) {
                    m_trade.PositionModify(ticket, newSL, tp);
                }
            }
        }
    }
};

//+------------------------------------------------------------------+
//| Enhanced Neuroplastic Brain - ZENITH OPTIMIZED LOGIC           |
//+------------------------------------------------------------------+
class EnhancedNeuroplasticBrain : public NeuroplasticBrain {
private:
    MomentumFlowOscillator* m_mfo;
    MarketStructureAnalyzer* m_msa;
    VolumeProfileAnalyzer* m_vpa;
    PositionManager* m_posManager;

    struct PatternMemory {
        double mfoValue;
        double structureBias;
        double volumeImbalance;
        MARKET_REGIME regime;
        double outcome;
        datetime timestamp;
    };

    PatternMemory m_memory[];
    int m_memoryIndex;

    double m_entryThreshold;
    double m_exitThreshold;

    datetime m_lastTradeTime;
    datetime m_lastBarTime;
    int m_atrHandle;
    double m_atrBuffer[];

public:
    EnhancedNeuroplasticBrain() {
        m_mfo = new MomentumFlowOscillator();
        m_msa = new MarketStructureAnalyzer();
        m_vpa = new VolumeProfileAnalyzer();
        m_posManager = new PositionManager();

        ArrayResize(m_memory, 1000);
        m_memoryIndex = 0;

        m_entryThreshold = 0.6;
        m_exitThreshold = 0.3;

        m_lastTradeTime = 0;
        m_lastBarTime = 0;

        m_atrHandle = iATR(_Symbol, PERIOD_M5, 14);
        ArrayResize(m_atrBuffer, 1);
        ArraySetAsSeries(m_atrBuffer, true);
    }

    ~EnhancedNeuroplasticBrain() {
        delete m_mfo;
        delete m_msa;
        delete m_vpa;
        delete m_posManager;
        if(m_atrHandle != INVALID_HANDLE) IndicatorRelease(m_atrHandle);
    }

    virtual void Process() override {
        // ZENITH OPTIMIZATION: Event Gating
        datetime currentBarTime = iTime(_Symbol, PERIOD_M5, 0);
        bool isNewBar = (currentBarTime != m_lastBarTime);
        if(isNewBar) m_lastBarTime = currentBarTime;

        // Update ATR cache for Position Manager once per tick
        m_posManager.UpdateATR();

        // 1. Momentum: Fast calculation, safe to run every tick
        double momentum = m_mfo.CalculateFlow();

        // 2. Structure & Profile: Heavy O(N) ops. RUN ONLY ON NEW BAR.
        if (isNewBar) {
            m_msa.AnalyzeStructure();
            m_vpa.BuildProfile();
        }

        double structureBias = m_msa.GetStructureBias();
        double volumeImbalance = m_vpa.GetImbalance();

        // 3. Regime Detection & Logic (On New Bar only to ensure stability)
        if (isNewBar) {
            DetectRegime(momentum, structureBias, volumeImbalance);

            double activation = CalculateActivation(momentum, structureBias, volumeImbalance);
            StorePattern(momentum, structureBias, volumeImbalance, activation);

            // Periodic synaptic pruning
            static int tickCount = 0;
            if(++tickCount % 100 == 0) {
                m_mfo.PruneWeights();
            }

            // Trading decision with refractory period
            if(MathAbs(activation) > m_entryThreshold) {
                if(TimeCurrent() - m_lastTradeTime > REFRACTORY_MS / 1000) {
                    ExecuteTrade(activation);
                    m_lastTradeTime = TimeCurrent();
                }
            }

            AdaptThresholds();
        }

        // 4. Position Management: Must run every tick for trailing stops
        m_posManager.ManagePositions();
    }

    //--- TRUE HEBBIAN LEARNING: Update weights based on reward
    virtual void RewardLearning(double profit) override {
        // Normalize profit as reward signal
        double reward = MathTanh(profit / 100.0);

        // Update component weights via Hebbian learning
        m_mfo.UpdateWeights(reward);

        // Update global plasticity based on performance
        if(profit > 0) {
            m_stressLevel = MathMax(0.0, m_stressLevel - 0.05);
            m_globalPlasticity += (1.0 - m_globalPlasticity) * 0.1;
        } else {
            m_stressLevel = MathMin(1.0, m_stressLevel + 0.1);
            m_globalPlasticity *= 0.95;
        }

        // Record in performance tracker
        if(m_perfTracker != NULL) {
            m_perfTracker.RecordTrade(profit, 0.1, m_marketRegime);
        }
    }

    double CalculateActivation(double momentum, double structure, double volume) {
        double w_momentum = 0.4;
        double w_structure = 0.3;
        double w_volume = 0.3;

        switch(m_marketRegime) {
            case REGIME_TRENDING_BULL:
            case REGIME_TRENDING_BEAR:
                w_momentum = 0.5;
                w_structure = 0.2;
                w_volume = 0.3;
                break;

            case REGIME_VOLATILE:
                w_momentum = 0.3;
                w_structure = 0.4;
                w_volume = 0.3;
                break;

            case REGIME_QUIET:
                w_momentum = 0.3;
                w_structure = 0.3;
                w_volume = 0.4;
                break;
        }

        double activation = momentum * w_momentum +
                          structure * w_structure +
                          volume * w_volume;

        activation *= (1.0 - m_stressLevel * 0.3);
        activation *= m_globalPlasticity;

        return MathTanh(activation);
    }

    void DetectRegime(double momentum, double structure, double volume) {
        MARKET_REGIME previousRegime = m_marketRegime;

        // Reuse persistent handle
        if(m_atrHandle != INVALID_HANDLE) {
            CopyBuffer(m_atrHandle, 0, 0, 1, m_atrBuffer);
        }

        double volatility = 0.0;
        if(ArraySize(m_atrBuffer) > 0) {
            volatility = m_atrBuffer[0] / _Point;
        }

        if(volatility > 200) {
            m_marketRegime = REGIME_VOLATILE;
        } else if(volatility < 50) {
            m_marketRegime = REGIME_QUIET;
        } else if(MathAbs(momentum) > 0.5 && structure * momentum > 0) {
            m_marketRegime = (momentum > 0) ? REGIME_TRENDING_BULL : REGIME_TRENDING_BEAR;
        } else {
            m_marketRegime = REGIME_RANGING;
        }

        if(previousRegime != m_marketRegime) {
            m_stressLevel = MathMin(1.0, m_stressLevel + 0.2);
            m_globalPlasticity *= 1.5;
        } else {
            m_stressLevel *= 0.95;
            m_globalPlasticity += (1.0 - m_globalPlasticity) * METAPLASTICITY_RATE;
        }
    }

    void StorePattern(double mfo, double structure, double volume, double activation) {
        m_memory[m_memoryIndex].mfoValue = mfo;
        m_memory[m_memoryIndex].structureBias = structure;
        m_memory[m_memoryIndex].volumeImbalance = volume;
        m_memory[m_memoryIndex].regime = m_marketRegime;
        m_memory[m_memoryIndex].outcome = activation;
        m_memory[m_memoryIndex].timestamp = TimeCurrent();

        m_memoryIndex = (m_memoryIndex + 1) % ArraySize(m_memory);
    }

    void ExecuteTrade(double signal) {
        double lotSize = CalculateKellySize(signal);
        m_posManager.OpenPosition(signal, lotSize, m_marketRegime);
    }

    //--- REAL KELLY CRITERION: Uses actual trade history
    double CalculateKellySize(double confidence) {
        double winRate = 0.55;
        double avgWin = 2.0;
        double avgLoss = 1.0;

        // Use real performance data if available
        if(m_perfTracker != NULL && m_perfTracker.GetTradeCount() >= MIN_TRADES_FOR_KELLY) {
            winRate = m_perfTracker.GetWinRate(m_marketRegime);
            avgWin = m_perfTracker.GetAvgWin();
            avgLoss = m_perfTracker.GetAvgLoss();

            if(avgLoss <= 0) avgLoss = 1.0;
        }

        double winLossRatio = avgWin / avgLoss;
        double kelly = (winRate * winLossRatio - (1 - winRate)) / winLossRatio;

        kelly = MathMax(0.0, kelly);
        kelly *= MathAbs(confidence);
        kelly *= KELLY_FRACTION;

        double balance = AccountInfoDouble(ACCOUNT_BALANCE);
        double riskAmount = balance * MathMin(0.02, kelly);

        double lotSize = NormalizeDouble(riskAmount / 10000, 2);
        return MathMax(SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN), lotSize);
    }

    void AdaptThresholds() {
        if(m_marketRegime == REGIME_VOLATILE) {
            m_entryThreshold = MathMin(0.8, m_entryThreshold + 0.01);
        } else {
            m_entryThreshold = MathMax(0.5, m_entryThreshold - 0.005);
        }
    }

    MomentumFlowOscillator* GetMFO() { return m_mfo; }
    MarketStructureAnalyzer* GetMSA() { return m_msa; }
    VolumeProfileAnalyzer* GetVPA() { return m_vpa; }
};

//+------------------------------------------------------------------+
//| BioDashboard - Visual Feedback System                           |
//+------------------------------------------------------------------+
class BioDashboard {
private:
    uint m_lastUpdate;
    uint m_updateInterval;

public:
    BioDashboard() {
        m_lastUpdate = 0;
        m_updateInterval = 1000; // 1 second throttle
    }

    void Update(EnhancedNeuroplasticBrain* brain) {
        if(brain == NULL) return;
        if(GetTickCount() - m_lastUpdate < m_updateInterval) return;

        string regimeIcon = "";
        switch(brain.GetCurrentRegime()) {
            case REGIME_TRENDING_BULL: regimeIcon = "🟢 BULL"; break;
            case REGIME_TRENDING_BEAR: regimeIcon = "🔴 BEAR"; break;
            case REGIME_VOLATILE:      regimeIcon = "⚡ VOLATILE"; break;
            case REGIME_QUIET:         regimeIcon = "😴 QUIET"; break;
            default:                   regimeIcon = "⚪ RANGING"; break;
        }

        string stressBar = "";
        int stressLevel = (int)(brain.GetStressLevel() * 10);
        for(int i=0; i<10; i++) stressBar += (i < stressLevel) ? "█" : "░";

        string plasticityBar = "";
        int plasticityLevel = (int)(brain.GetPlasticity() * 10);
        for(int i=0; i<10; i++) plasticityBar += (i < plasticityLevel) ? "⚡" : " ";

        double winRate = 0;
        if(brain.GetPerfTracker() != NULL) winRate = brain.GetPerfTracker().GetWinRate() * 100;

        string dashboard = StringFormat(
            "🧠 NEUROPLASTIC BRAIN v3.1 (ZENITH)\n" +
            "--------------------------------\n" +
            "Market Pulse:   %s\n" +
            "Cortisol (Stress): [%s] %.2f\n" +
            "Synaptic State:    [%s] %.2f\n" +
            "Win Rate:       %.1f%%\n" +
            "Momentum Flow:  %.4f\n" +
            "Structure Bias: %.4f",
            regimeIcon,
            stressBar, brain.GetStressLevel(),
            plasticityBar, brain.GetPlasticity(),
            winRate,
            brain.GetMFO().GetFlowStrength(),
            brain.GetMSA().GetStructureBias()
        );

        Comment(dashboard);
        m_lastUpdate = GetTickCount();
    }

    void Clear() { Comment(""); }
};

//+------------------------------------------------------------------+
//| Custom Indicator Integration - OPTIMIZED                        |
//+------------------------------------------------------------------+
class CustomIndicators {
private:
    int m_rsiHandle;
    int m_macdHandle;
    int m_bbHandle;
    double m_rsiBuffer[]; // Reuse

public:
    CustomIndicators() {
        m_rsiHandle = iRSI(_Symbol, PERIOD_M5, 14, PRICE_CLOSE);
        m_macdHandle = iMACD(_Symbol, PERIOD_M5, 12, 26, 9, PRICE_CLOSE);
        m_bbHandle = iBands(_Symbol, PERIOD_M5, 20, 0, 2, PRICE_CLOSE);
        ArrayResize(m_rsiBuffer, 10);
        ArraySetAsSeries(m_rsiBuffer, true);
    }

    ~CustomIndicators() {
        if(m_rsiHandle != INVALID_HANDLE) IndicatorRelease(m_rsiHandle);
        if(m_macdHandle != INVALID_HANDLE) IndicatorRelease(m_macdHandle);
        if(m_bbHandle != INVALID_HANDLE) IndicatorRelease(m_bbHandle);
    }

    double GetRSIDivergence() {
        if(CopyBuffer(m_rsiHandle, 0, 0, 10, m_rsiBuffer) < 10) return 0.0;

        double priceTrend = (iClose(_Symbol, PERIOD_M5, 0) - iClose(_Symbol, PERIOD_M5, 9)) / iClose(_Symbol, PERIOD_M5, 9);
        double rsiTrend = (m_rsiBuffer[0] - m_rsiBuffer[9]) / 100.0;

        if(priceTrend * rsiTrend < 0) {
            return rsiTrend - priceTrend;
        }

        return 0.0;
    }
};

//--- Global instances
EnhancedNeuroplasticBrain* enhancedBrain;
CustomIndicators* indicators;
BioDashboard* dashboard;

//+------------------------------------------------------------------+
//| Expert initialization                                           |
//+------------------------------------------------------------------+
int OnInit() {
    enhancedBrain = new EnhancedNeuroplasticBrain();
    indicators = new CustomIndicators();
    dashboard = new BioDashboard();

    Print("Enhanced Neuroplastic EA v3.1 (ZENITH) initialized");
    Print("Synaptic architecture: ONLINE");
    Print("Market consciousness: ENGAGED");
    Print("True Hebbian learning: ACTIVE");

    return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert deinitialization                                         |
//+------------------------------------------------------------------+
void OnDeinit(const int reason) {
    if(enhancedBrain != NULL) delete enhancedBrain;
    if(indicators != NULL) delete indicators;
    if(dashboard != NULL) {
        dashboard.Clear();
        delete dashboard;
    }

    Print("Neural pathways dissolved. System offline.");
}

//+------------------------------------------------------------------+
//| Expert tick function                                            |
//+------------------------------------------------------------------+
void OnTick() {
    if(enhancedBrain != NULL) {
        enhancedBrain.Process();
        if(dashboard != NULL) dashboard.Update(enhancedBrain);
    }

    // Learn from closed trades
    static int lastHistoryTotal = 0;
    int currentHistoryTotal = HistoryDealsTotal();

    if(currentHistoryTotal > lastHistoryTotal) {
        ulong ticket = HistoryDealGetTicket(currentHistoryTotal - 1);
        if(ticket > 0) {
            double profit = HistoryDealGetDouble(ticket, DEAL_PROFIT);
            if(profit != 0 && enhancedBrain != NULL) {
                enhancedBrain.RewardLearning(profit);
            }
        }
        lastHistoryTotal = currentHistoryTotal;
    }

    // Hourly status report
    static datetime lastReport = 0;
    if(TimeCurrent() - lastReport > 3600) {
        ReportSystemStatus();
        lastReport = TimeCurrent();
    }
}

//+------------------------------------------------------------------+
//| System status reporting                                         |
//+------------------------------------------------------------------+
void ReportSystemStatus() {
    if(enhancedBrain == NULL) return;

    Print("=== Neuroplastic System Status ===");
    Print("Current Regime: ", EnumToString(enhancedBrain.GetCurrentRegime()));
    Print("Stress Level: ", DoubleToString(enhancedBrain.GetStressLevel(), 3));
    Print("Global Plasticity: ", DoubleToString(enhancedBrain.GetPlasticity(), 3));

    TradePerformanceTracker* perf = enhancedBrain.GetPerfTracker();
    if(perf != NULL) {
        Print("Total Trades: ", perf.GetTradeCount());
        Print("Win Rate: ", DoubleToString(perf.GetWinRate() * 100, 1), "%");
        Print("Avg Win: ", DoubleToString(perf.GetAvgWin(), 2));
        Print("Avg Loss: ", DoubleToString(perf.GetAvgLoss(), 2));
    }

    MomentumFlowOscillator* mfo = enhancedBrain.GetMFO();
    MarketStructureAnalyzer* msa = enhancedBrain.GetMSA();
    VolumeProfileAnalyzer* vpa = enhancedBrain.GetVPA();

    if(mfo != NULL) {
        Print("Momentum Flow: ", DoubleToString(mfo.GetFlowStrength(), 4));
        double weights[];
        mfo.GetWeights(weights);
        if(ArraySize(weights) >= 3) {
            Print("MFO Weights: [", DoubleToString(weights[0], 2), ", ",
                  DoubleToString(weights[1], 2), ", ", DoubleToString(weights[2], 2), "]");
        }
    }
    if(msa != NULL) Print("Structure Bias: ", DoubleToString(msa.GetStructureBias(), 4));
    if(vpa != NULL) Print("Volume Imbalance: ", DoubleToString(vpa.GetImbalance(), 4));

    Print("================================");
}

//+------------------------------------------------------------------+
//| Tester function - Enhanced Neuro-Fitness Metric                 |
//+------------------------------------------------------------------+
double OnTester() {
    double profit = TesterStatistics(STAT_PROFIT);
    double drawdown = TesterStatistics(STAT_EQUITY_DDREL_PERCENT);
    double trades = TesterStatistics(STAT_TRADES);

    if(trades < 10) return 0.0;

    double sharpe = TesterStatistics(STAT_SHARPE_RATIO);
    if(sharpe < 0) sharpe = 0;

    // Neuro-Fitness: Rewards profit & stability, penalizes high stress
    double plasticity = (enhancedBrain != NULL) ? enhancedBrain.GetPlasticity() : 1.0;
    double fitness = sharpe * (1.0 - drawdown / 100.0) * plasticity;

    return fitness;
}
//+------------------------------------------------------------------+
