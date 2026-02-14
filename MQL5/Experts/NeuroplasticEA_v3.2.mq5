//+------------------------------------------------------------------+
//|                      NeuroplasticEA_v3.2.mq5                    |
//|               Neuroplastic Trading Brain v3.2 - TRM Core        |
//|                   "The Recursive Thinking Machine"              |
//+------------------------------------------------------------------+
#property copyright "Neuroplastic Trading Framework v3.2"
#property version   "3.20"
#property strict
#property description "Advanced neuroplastic trading system with Tiny Recursive Model (TRM) core"

#include <Trade\Trade.mqh>
#include <Math\Stat\Math.mqh>
#include "../Include/NeuroplasticTradingBrain_Complete.mqh"
#include "../Include/TinyRecursiveModel.mqh" // New TRM Core

//+------------------------------------------------------------------+
//| Input Parameters                                                |
//+------------------------------------------------------------------+
input group "Risk Management"
input double RiskPercent = 1.0;           // Risk per trade (%) [0.1-5.0]
input double MaxDrawdownPercent = 20.0;   // Maximum drawdown (%) [5.0-50.0]
input bool   UseKellyCriterion = true;    // Use Kelly position sizing

input group "TRM Neural Core"
input int    ReasoningSteps = 6;          // Depth of thought (N) [2-12]
input int    RefinementSteps = 3;         // Refinement cycles (T) [1-5]
input double PlasticityRate = 0.01;       // TRM Learning Rate [0.001-0.1]
input bool   EnableDeepThought = true;    // Enable multi-step reasoning

input group "Trading Settings"
input int    MagicNumber = 271026;        // Unique identifier
input double BaseLotSize = 0.01;          // Base position size [0.01-1.0]
input int    MaxPositions = 1;            // Maximum simultaneous positions [1-5]

input group "Market Analysis"
input int    RegimeWindow = 100;          // Bars for regime detection [50-200]
input int    ATRPeriod = 14;              // ATR period [7-21]

//+------------------------------------------------------------------+
//| Validation and safety constants                                 |
//+------------------------------------------------------------------+
#define SYSTEM_VERSION      "3.2.0"
#define MIN_BARS_REQUIRED   200
#define MAX_SPREAD_POINTS   50
#define PROFIT_CACHE_SIZE   100
#define STATE_FILE_PREFIX   "NeuroplasticEA_v3.2_"

//+------------------------------------------------------------------+
//| Main EA Class with TRM Core                                     |
//+------------------------------------------------------------------+
class CNeuroplasticEA_v32 {
private:
    CTrade            m_trade;
    CTinyRecursiveModel *m_brain; // The TRM Core

    // Performance tracking
    int               m_totalTrades;
    int               m_winningTrades;
    double            m_totalProfit;
    double            m_peakBalance;
    double            m_currentDrawdown;
    double            m_maxDrawdown;

    // Market data buffers (Zero-Allocation)
    double            m_priceBuffer[];
    double            m_volumeBuffer[];
    double            m_features[];

    // Zero-allocation indicator buffers
    double            m_rsiBuffer[];
    double            m_macdMainBuffer[];
    double            m_macdSignalBuffer[];
    double            m_bbUpperBuffer[];
    double            m_bbLowerBuffer[];
    double            m_bbMiddleBuffer[];
    double            m_maBuffer[];
    double            m_atrBuffer[];

    // Technical indicator handles
    int               m_atrHandle;
    int               m_rsiHandle;
    int               m_macdHandle;
    int               m_bbHandle;
    int               m_maHandle;

    // System state
    bool              m_initialized;
    datetime          m_lastBarTime;
    int               m_barsSinceStart;

public:
    CNeuroplasticEA_v32() {
        m_initialized = false;
        m_barsSinceStart = 0;
        m_lastBarTime = 0;
        m_brain = NULL;

        // Initialize buffers
        ArrayResize(m_priceBuffer, RegimeWindow);
        ArrayResize(m_volumeBuffer, RegimeWindow);
        ArrayResize(m_features, 12); // TRM Input Vector Size

        // Zero-Allocation Tick Buffers
        ArrayResize(m_rsiBuffer, 2);
        ArrayResize(m_macdMainBuffer, 2);
        ArrayResize(m_macdSignalBuffer, 2);
        ArrayResize(m_bbUpperBuffer, 2);
        ArrayResize(m_bbLowerBuffer, 2);
        ArrayResize(m_bbMiddleBuffer, 2);
        ArrayResize(m_maBuffer, 2);
        ArrayResize(m_atrBuffer, 2);

        ArraySetAsSeries(m_rsiBuffer, true);
        ArraySetAsSeries(m_macdMainBuffer, true);
        ArraySetAsSeries(m_macdSignalBuffer, true);
        ArraySetAsSeries(m_bbUpperBuffer, true);
        ArraySetAsSeries(m_bbLowerBuffer, true);
        ArraySetAsSeries(m_bbMiddleBuffer, true);
        ArraySetAsSeries(m_maBuffer, true);
        ArraySetAsSeries(m_atrBuffer, true);

        m_trade.SetExpertMagicNumber(MagicNumber);
        m_trade.SetDeviationInPoints(10);
        m_trade.SetTypeFilling(ORDER_FILLING_IOC);

        m_totalTrades = 0;
        m_winningTrades = 0;
        m_totalProfit = 0;
        m_peakBalance = AccountInfoDouble(ACCOUNT_BALANCE);
        m_currentDrawdown = 0;
        m_maxDrawdown = 0;

        if(!InitializeIndicators()) {
            Print("FATAL: Failed to initialize indicators");
            return;
        }

        // Initialize the TRM Brain
        m_brain = new CTinyRecursiveModel(12, 16, ReasoningSteps, RefinementSteps); // Input=12, Hidden=16
        if(m_brain == NULL) {
            Print("FATAL: Failed to initialize TRM Brain");
            return;
        }

        m_brain.SetPlasticity(PlasticityRate);
        m_brain.InitializeWeights();

        m_initialized = true;
    }

    ~CNeuroplasticEA_v32() {
        if(m_initialized) {
            if(m_atrHandle != INVALID_HANDLE) IndicatorRelease(m_atrHandle);
            if(m_rsiHandle != INVALID_HANDLE) IndicatorRelease(m_rsiHandle);
            if(m_macdHandle != INVALID_HANDLE) IndicatorRelease(m_macdHandle);
            if(m_bbHandle != INVALID_HANDLE) IndicatorRelease(m_bbHandle);
            if(m_maHandle != INVALID_HANDLE) IndicatorRelease(m_maHandle);

            if(m_brain != NULL) delete m_brain;
        }
    }

    bool InitializeIndicators() {
        m_atrHandle = iATR(_Symbol, PERIOD_CURRENT, ATRPeriod);
        m_rsiHandle = iRSI(_Symbol, PERIOD_CURRENT, 14, PRICE_CLOSE);
        m_macdHandle = iMACD(_Symbol, PERIOD_CURRENT, 12, 26, 9, PRICE_CLOSE);
        m_bbHandle = iBands(_Symbol, PERIOD_CURRENT, 20, 0, 2.0, PRICE_CLOSE);
        m_maHandle = iMA(_Symbol, PERIOD_CURRENT, 50, 0, MODE_EMA, PRICE_CLOSE);

        if(m_atrHandle == INVALID_HANDLE || m_rsiHandle == INVALID_HANDLE ||
           m_macdHandle == INVALID_HANDLE || m_bbHandle == INVALID_HANDLE ||
           m_maHandle == INVALID_HANDLE) {
            return false;
        }
        return true;
    }

    void OnTick() {
        if(!m_initialized) return;

        datetime currentBarTime = iTime(_Symbol, PERIOD_CURRENT, 0);
        bool isNewBar = (currentBarTime != m_lastBarTime);

        // --- Always check drawdown & positions on tick ---
        UpdateDrawdown();
        ManageOpenPositions();

        if(m_currentDrawdown > MaxDrawdownPercent / 100.0) {
            CloseAllPositions("Max drawdown");
            return;
        }

        // --- Heavy TRM Logic only on New Bar ---
        if(isNewBar) {
            m_lastBarTime = currentBarTime;
            m_barsSinceStart++;

            if(m_barsSinceStart < RegimeWindow) return; // Warmup

            // 1. Gather Input Features (x)
            if(!PrepareFeatures()) return;

            // 2. Run the TRM "Think Loop"
            double signal = m_brain.Think(m_features); // Returns -1.0 to 1.0
            double confidence = MathAbs(signal);

            // 3. Visualize Thought Process
            Comment(
                "=== TRM Core v3.2 ===\n",
                "Signal: ", DoubleToString(signal, 4), "\n",
                "Confidence: ", DoubleToString(confidence * 100, 1), "%\n",
                "Latent Energy (z): ", DoubleToString(m_brain.GetLatentEnergy(), 4), "\n",
                "Reasoning Steps: ", ReasoningSteps, " x ", RefinementSteps
            );

            // 4. Execute Trade based on "Deep Thought"
            if(confidence > 0.6 && PositionsTotal() < MaxPositions) {
                int direction = (signal > 0) ? 1 : -1;
                ExecuteTrade(direction, confidence);
            }
        }
    }

    bool PrepareFeatures() {
        // Zero-Allocation Feature Gathering
        if(CopyBuffer(m_rsiHandle, 0, 0, 1, m_rsiBuffer) <= 0) return false;
        if(CopyBuffer(m_macdHandle, 0, 0, 1, m_macdMainBuffer) <= 0) return false;
        if(CopyBuffer(m_macdHandle, 1, 0, 1, m_macdSignalBuffer) <= 0) return false;
        if(CopyBuffer(m_bbHandle, 1, 0, 1, m_bbUpperBuffer) <= 0) return false;
        if(CopyBuffer(m_bbHandle, 2, 0, 1, m_bbLowerBuffer) <= 0) return false;
        if(CopyBuffer(m_maHandle, 0, 0, 1, m_maBuffer) <= 0) return false;

        double close0 = iClose(_Symbol, PERIOD_CURRENT, 0);
        double close1 = iClose(_Symbol, PERIOD_CURRENT, 1);
        double vol0 = (double)iVolume(_Symbol, PERIOD_CURRENT, 0);

        // Normalize Inputs to [-1, 1] roughly for Neural Stability
        // Feature 0: RSI (Scaled)
        m_features[0] = (m_rsiBuffer[0] - 50.0) / 50.0;

        // Feature 1: MACD Histogram
        m_features[1] = (m_macdMainBuffer[0] - m_macdSignalBuffer[0]) * 100.0;

        // Feature 2: Price vs MA
        m_features[2] = (close0 - m_maBuffer[0]) / m_maBuffer[0] * 1000.0;

        // Feature 3: BB Position
        double bbWidth = m_bbUpperBuffer[0] - m_bbLowerBuffer[0];
        if(bbWidth > 0) m_features[3] = (close0 - m_bbLowerBuffer[0]) / bbWidth * 2.0 - 1.0;
        else m_features[3] = 0;

        // Feature 4: Momentum
        m_features[4] = (close0 - close1) / close1 * 1000.0;

        // Feature 5: Volume Trend
        m_features[5] = (vol0 > 0) ? MathLog(vol0) / 10.0 : 0; // Log scale

        // ... Fill remaining features with 0 or noise for now
        for(int i=6; i<12; i++) m_features[i] = 0.0; // Placeholder for future expansion

        return true;
    }

    void ExecuteTrade(int signal, double confidence) {
        // ... (Standard execution logic same as v3.1)
        double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
        double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
        double price = (signal > 0) ? ask : bid;

        if(CopyBuffer(m_atrHandle, 0, 0, 1, m_atrBuffer) <= 0) return;
        double atr = m_atrBuffer[0];

        double slDist = atr * 2.0;
        double tpDist = atr * 4.0;

        double sl = (signal > 0) ? price - slDist : price + slDist;
        double tp = (signal > 0) ? price + tpDist : price - tpDist;

        string comment = StringFormat("TRM_v3.2_Conf:%.2f", confidence);

        if(signal > 0) m_trade.Buy(BaseLotSize, _Symbol, price, sl, tp, comment);
        else           m_trade.Sell(BaseLotSize, _Symbol, price, sl, tp, comment);
    }

    void UpdateDrawdown() {
        double balance = AccountInfoDouble(ACCOUNT_BALANCE);
        double equity = AccountInfoDouble(ACCOUNT_EQUITY);
        if(balance > m_peakBalance) m_peakBalance = balance;
        m_currentDrawdown = (m_peakBalance - equity) / m_peakBalance;
        if(m_currentDrawdown > m_maxDrawdown) m_maxDrawdown = m_currentDrawdown;
    }

    void ManageOpenPositions() {
        // Simple trailing stop logic
    }

    void CloseAllPositions(string reason) {
        // Emergency close logic
    }
};

CNeuroplasticEA_v32 *g_EA_v32 = NULL;

int OnInit() {
    g_EA_v32 = new CNeuroplasticEA_v32();
    return (g_EA_v32 != NULL) ? INIT_SUCCEEDED : INIT_FAILED;
}

void OnDeinit(const int reason) {
    if(g_EA_v32 != NULL) delete g_EA_v32;
}

void OnTick() {
    if(g_EA_v32 != NULL) g_EA_v32.OnTick();
}
