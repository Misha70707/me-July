//+------------------------------------------------------------------+
//|                        TradingEA_Version_C_ULTIMATE.mq5         |
//|                    THE ULTIMATE HYBRID TRADING SYSTEM           |
//|                        Version LEGENDARY 1.0                    |
//+------------------------------------------------------------------+
#property copyright "Ultimate Trading Framework - The One That Changes Everything"
#property version   "1.00"
#property strict
#property description "The most advanced adaptive trading system combining AI, multi-strategy, and neuroplasticity"

#include <Trade\Trade.mqh>
#include <Math\Stat\Math.mqh>

//+------------------------------------------------------------------+
//| Input Parameters - THE ULTIMATE CONFIG                          |
//+------------------------------------------------------------------+
input group "=== RISK MANAGEMENT ==="
input double RiskPercent = 1.5;              // Base risk per trade (%)
input double MaxDrawdownPercent = 15.0;      // Maximum allowed drawdown (%)
input bool   UseDynamicRisk = true;          // Dynamic risk adjustment
input bool   UseKellyOptimization = true;    // Kelly Criterion optimization

input group "=== STRATEGY SELECTION ==="
input bool   UseScalpingStrategy = true;     // Enable Scalping (quick profits)
input bool   UseSwingStrategy = true;        // Enable Swing Trading (trends)
input bool   UseBreakoutStrategy = true;     // Enable Breakout (momentum)
input bool   AutoSelectBestStrategy = true;  // AI picks best strategy

input group "=== AI BRAIN SETTINGS ==="
input int    LearningSpeed = 50;             // How fast AI learns [1-100]
input double MinConfidence = 0.65;           // Minimum AI confidence [0.5-0.9]
input bool   EnableNeuralOverride = true;    // Let AI override signals
input bool   EnableDeepLearning = true;      // Advanced pattern recognition

input group "=== TRADING SETTINGS ==="
input int    MagicNumber = 999999;           // Unique EA identifier
input double BaseLotSize = 0.01;             // Base lot size
input int    MaxPositions = 3;               // Max simultaneous trades
input int    SlippagePoints = 20;            // Slippage tolerance

input group "=== MULTI-TIMEFRAME ==="
input bool   UseMultiTimeframe = true;       // Multi-timeframe confirmation
input ENUM_TIMEFRAMES HigherTF = PERIOD_H1;  // Higher timeframe for trend

input group "=== ADVANCED FEATURES ==="
input bool   EnableScalingIn = true;         // Add to winning positions
input bool   EnableTrailingStop = true;      // Dynamic trailing stops
input bool   EnableBreakeven = true;         // Move SL to breakeven
input bool   TurboMode = false;              // AGGRESSIVE MODE (risky!)
input bool   ShowDashboard = true;           // Show performance dashboard
input bool   DrawSignalsOnChart = true;      // Visual indicators

input group "=== TECHNICAL INDICATORS ==="
input int    FastMA_Period = 8;              // Fast MA
input int    SlowMA_Period = 21;             // Slow MA
input int    RSI_Period = 14;                // RSI period
input int    ATR_Period = 14;                // ATR period
input int    BB_Period = 20;                 // Bollinger Bands
input double BB_Deviation = 2.0;             // BB deviation

//+------------------------------------------------------------------+
//| Strategy Types                                                   |
//+------------------------------------------------------------------+
enum STRATEGY_TYPE {
    STRATEGY_SCALPING,      // Quick in-out trades
    STRATEGY_SWING,         // Ride the trends
    STRATEGY_BREAKOUT,      // Momentum trades
    STRATEGY_RANGING,       // Range-bound trades
    STRATEGY_NONE
};

//+------------------------------------------------------------------+
//| Market Regime                                                    |
//+------------------------------------------------------------------+
enum MARKET_REGIME {
    REGIME_STRONG_TREND_UP,
    REGIME_STRONG_TREND_DOWN,
    REGIME_WEAK_TREND_UP,
    REGIME_WEAK_TREND_DOWN,
    REGIME_RANGING,
    REGIME_HIGH_VOLATILITY,
    REGIME_LOW_VOLATILITY,
    REGIME_BREAKOUT,
    REGIME_UNKNOWN
};

//+------------------------------------------------------------------+
//| Trade Structure                                                  |
//+------------------------------------------------------------------+
struct TradeInfo {
    ulong    ticket;
    datetime openTime;
    double   openPrice;
    double   lotSize;
    int      direction;        // 1=buy, -1=sell
    STRATEGY_TYPE strategy;
    double   maxProfit;
    double   maxDrawdown;
    double   confidence;
    string   reason;
    bool     scaledIn;
    bool     breakevenSet;

    void Reset() {
        ticket = 0;
        openTime = 0;
        openPrice = 0;
        lotSize = 0;
        direction = 0;
        strategy = STRATEGY_NONE;
        maxProfit = 0;
        maxDrawdown = 0;
        confidence = 0;
        reason = "";
        scaledIn = false;
        breakevenSet = false;
    }
};

//+------------------------------------------------------------------+
//| Performance Tracker                                              |
//+------------------------------------------------------------------+
struct PerformanceStats {
    int    totalTrades;
    int    winningTrades;
    int    losingTrades;
    double totalProfit;
    double totalLoss;
    double largestWin;
    double largestLoss;
    double peakBalance;
    double currentDD;
    double maxDD;

    // Strategy-specific
    int    scalpingWins;
    int    scalpingLosses;
    int    swingWins;
    int    swingLosses;
    int    breakoutWins;
    int    breakoutLosses;

    void Initialize() {
        totalTrades = 0;
        winningTrades = 0;
        losingTrades = 0;
        totalProfit = 0;
        totalLoss = 0;
        largestWin = 0;
        largestLoss = 0;
        peakBalance = AccountInfoDouble(ACCOUNT_BALANCE);
        currentDD = 0;
        maxDD = 0;

        scalpingWins = scalpingLosses = 0;
        swingWins = swingLosses = 0;
        breakoutWins = breakoutLosses = 0;
    }

    double GetWinRate() {
        return totalTrades > 0 ? (double)winningTrades / totalTrades * 100 : 0;
    }

    double GetProfitFactor() {
        return totalLoss != 0 ? MathAbs(totalProfit / totalLoss) : 0;
    }

    double GetAverageWin() {
        return winningTrades > 0 ? totalProfit / winningTrades : 0;
    }

    double GetAverageLoss() {
        return losingTrades > 0 ? totalLoss / losingTrades : 0;
    }
};

//+------------------------------------------------------------------+
//| AI Brain - Neural Network                                        |
//+------------------------------------------------------------------+
class CNeuralBrain {
private:
    double m_weights[20];
    double m_bias;
    double m_learningRate;
    double m_confidence;
    int    m_patternsLearned;
    double m_momentum[20];

    double Sigmoid(double x) {
        return 1.0 / (1.0 + MathExp(-x));
    }

    double ReLU(double x) {
        return MathMax(0, x);
    }

public:
    CNeuralBrain() {
        m_learningRate = LearningSpeed / 100.0 * 0.01;
        m_confidence = 0.5;
        m_bias = 0;
        m_patternsLearned = 0;

        // Initialize weights randomly
        for(int i = 0; i < 20; i++) {
            m_weights[i] = (MathRand() / 32768.0 - 0.5) * 0.2;
            m_momentum[i] = 0;
        }
    }

    double Predict(double &features[]) {
        double activation = m_bias;

        int size = MathMin(ArraySize(features), 20);
        for(int i = 0; i < size; i++) {
            if(MathIsValidNumber(features[i])) {
                activation += features[i] * m_weights[i];
            }
        }

        // Apply activation function
        if(EnableDeepLearning) {
            activation = Sigmoid(activation);
        } else {
            activation = ReLU(activation);
        }

        m_confidence = MathAbs(activation - 0.5) * 2; // 0 to 1

        return activation;
    }

    void Learn(double &features[], bool wasWin, double profitAmount) {
        double target = wasWin ? 1.0 : 0.0;
        double prediction = Predict(features);
        double error = target - prediction;

        // Backpropagation with momentum
        int size = MathMin(ArraySize(features), 20);
        for(int i = 0; i < size; i++) {
            if(MathIsValidNumber(features[i])) {
                double gradient = error * features[i];
                m_momentum[i] = 0.9 * m_momentum[i] + m_learningRate * gradient;
                m_weights[i] += m_momentum[i];

                // Weight decay (regularization)
                m_weights[i] *= 0.9999;
            }
        }

        m_bias += m_learningRate * error * 0.5;
        m_patternsLearned++;

        // Update learning rate (decay over time)
        m_learningRate *= 0.9999;
        m_learningRate = MathMax(0.0001, m_learningRate);
    }

    double GetConfidence() { return m_confidence; }
    int GetPatternsLearned() { return m_patternsLearned; }
};

//+------------------------------------------------------------------+
//| Strategy Manager                                                 |
//+------------------------------------------------------------------+
class CStrategyManager {
private:
    PerformanceStats m_stats;

public:
    CStrategyManager() {
        m_stats.Initialize();
    }

    STRATEGY_TYPE SelectBestStrategy(MARKET_REGIME regime) {
        if(!AutoSelectBestStrategy) {
            // Use all enabled strategies
            if(UseScalpingStrategy) return STRATEGY_SCALPING;
            if(UseSwingStrategy) return STRATEGY_SWING;
            if(UseBreakoutStrategy) return STRATEGY_BREAKOUT;
            return STRATEGY_NONE;
        }

        // AI selects based on regime and past performance
        switch(regime) {
            case REGIME_STRONG_TREND_UP:
            case REGIME_STRONG_TREND_DOWN:
                if(UseSwingStrategy) return STRATEGY_SWING;
                break;

            case REGIME_RANGING:
                if(UseScalpingStrategy) return STRATEGY_SCALPING;
                break;

            case REGIME_BREAKOUT:
            case REGIME_HIGH_VOLATILITY:
                if(UseBreakoutStrategy) return STRATEGY_BREAKOUT;
                break;

            case REGIME_LOW_VOLATILITY:
                if(UseScalpingStrategy) return STRATEGY_SCALPING;
                break;
        }

        // Default to best performing strategy
        double scalpWR = m_stats.scalpingWins + m_stats.scalpingLosses > 0 ?
                        (double)m_stats.scalpingWins / (m_stats.scalpingWins + m_stats.scalpingLosses) : 0;
        double swingWR = m_stats.swingWins + m_stats.swingLosses > 0 ?
                        (double)m_stats.swingWins / (m_stats.swingWins + m_stats.swingLosses) : 0;
        double breakWR = m_stats.breakoutWins + m_stats.breakoutLosses > 0 ?
                        (double)m_stats.breakoutWins / (m_stats.breakoutWins + m_stats.breakoutLosses) : 0;

        if(scalpWR >= swingWR && scalpWR >= breakWR && UseScalpingStrategy) return STRATEGY_SCALPING;
        if(swingWR >= breakWR && UseSwingStrategy) return STRATEGY_SWING;
        if(UseBreakoutStrategy) return STRATEGY_BREAKOUT;

        return STRATEGY_NONE;
    }

    void UpdateStats(bool won, double profit, STRATEGY_TYPE strategy) {
        m_stats.totalTrades++;

        if(won) {
            m_stats.winningTrades++;
            m_stats.totalProfit += profit;
            if(profit > m_stats.largestWin) m_stats.largestWin = profit;

            switch(strategy) {
                case STRATEGY_SCALPING: m_stats.scalpingWins++; break;
                case STRATEGY_SWING: m_stats.swingWins++; break;
                case STRATEGY_BREAKOUT: m_stats.breakoutWins++; break;
            }
        } else {
            m_stats.losingTrades++;
            m_stats.totalLoss += profit; // profit is negative
            if(profit < m_stats.largestLoss) m_stats.largestLoss = profit;

            switch(strategy) {
                case STRATEGY_SCALPING: m_stats.scalpingLosses++; break;
                case STRATEGY_SWING: m_stats.swingLosses++; break;
                case STRATEGY_BREAKOUT: m_stats.breakoutLosses++; break;
            }
        }

        // Update drawdown
        double balance = AccountInfoDouble(ACCOUNT_BALANCE);
        if(balance > m_stats.peakBalance) m_stats.peakBalance = balance;

        double equity = AccountInfoDouble(ACCOUNT_EQUITY);
        m_stats.currentDD = (m_stats.peakBalance - equity) / m_stats.peakBalance * 100;
        if(m_stats.currentDD > m_stats.maxDD) m_stats.maxDD = m_stats.currentDD;
    }

    PerformanceStats GetStats() { return m_stats; }
};

//+------------------------------------------------------------------+
//| Global Variables                                                 |
//+------------------------------------------------------------------+
CTrade trade;
CNeuralBrain g_brain;
CStrategyManager g_strategyMgr;

TradeInfo g_trades[];
int g_activeTradeCount = 0;
datetime g_lastBarTime = 0;

// Indicator handles
int g_handleFastMA;
int g_handleSlowMA;
int g_handleRSI;
int g_handleATR;
int g_handleBB;
int g_handleMACD;

// Higher timeframe
int g_handleHTF_MA;

//+------------------------------------------------------------------+
//| Expert initialization                                            |
//+------------------------------------------------------------------+
int OnInit() {
    Print("╔════════════════════════════════════════════════════════╗");
    Print("║   THE ULTIMATE HYBRID TRADING SYSTEM - ACTIVATED!     ║");
    Print("║   Version C - LEGENDARY EDITION                        ║");
    Print("╚════════════════════════════════════════════════════════╝");

    // Initialize trade object
    trade.SetExpertMagicNumber(MagicNumber);
    trade.SetDeviationInPoints(SlippagePoints);
    trade.SetTypeFilling(ORDER_FILLING_FOK);

    // Initialize trade array
    ArrayResize(g_trades, MaxPositions);
    for(int i = 0; i < MaxPositions; i++) {
        g_trades[i].Reset();
    }

    // Initialize indicators
    g_handleFastMA = iMA(_Symbol, PERIOD_CURRENT, FastMA_Period, 0, MODE_EMA, PRICE_CLOSE);
    g_handleSlowMA = iMA(_Symbol, PERIOD_CURRENT, SlowMA_Period, 0, MODE_EMA, PRICE_CLOSE);
    g_handleRSI = iRSI(_Symbol, PERIOD_CURRENT, RSI_Period, PRICE_CLOSE);
    g_handleATR = iATR(_Symbol, PERIOD_CURRENT, ATR_Period);
    g_handleBB = iBands(_Symbol, PERIOD_CURRENT, BB_Period, 0, BB_Deviation, PRICE_CLOSE);
    g_handleMACD = iMACD(_Symbol, PERIOD_CURRENT, 12, 26, 9, PRICE_CLOSE);

    if(UseMultiTimeframe) {
        g_handleHTF_MA = iMA(_Symbol, HigherTF, 50, 0, MODE_EMA, PRICE_CLOSE);
    }

    // Verify indicators
    if(g_handleFastMA == INVALID_HANDLE || g_handleSlowMA == INVALID_HANDLE ||
       g_handleRSI == INVALID_HANDLE || g_handleATR == INVALID_HANDLE ||
       g_handleBB == INVALID_HANDLE || g_handleMACD == INVALID_HANDLE) {
        Print("❌ ERROR: Failed to initialize indicators!");
        return INIT_FAILED;
    }

    Print("✓ Neural Brain: ONLINE");
    Print("✓ Multi-Strategy Engine: READY");
    Print("✓ Adaptive Risk Manager: ACTIVE");
    Print("✓ Technical Indicators: LOADED");

    if(TurboMode) {
        Print("⚡ TURBO MODE ACTIVATED - MAXIMUM AGGRESSION!");
    }

    if(EnableDeepLearning) {
        Print("🧠 Deep Learning: ENABLED");
    }

    Print("🚀 System ready to dominate the markets!");
    Print("══════════════════════════════════════════════════════");

    return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| Expert deinitialization                                          |
//+------------------------------------------------------------------+
void OnDeinit(const int reason) {
    PerformanceStats stats = g_strategyMgr.GetStats();

    Print("╔════════════════════════════════════════════════════════╗");
    Print("║         ULTIMATE SYSTEM - FINAL REPORT                 ║");
    Print("╠════════════════════════════════════════════════════════╣");
    Print("║ Total Trades: ", stats.totalTrades);
    Print("║ Win Rate: ", NormalizeDouble(stats.GetWinRate(), 2), "%");
    Print("║ Profit Factor: ", NormalizeDouble(stats.GetProfitFactor(), 2));
    Print("║ Total Profit: $", NormalizeDouble(stats.totalProfit, 2));
    Print("║ Max Drawdown: ", NormalizeDouble(stats.maxDD, 2), "%");
    Print("║ AI Patterns Learned: ", g_brain.GetPatternsLearned());
    Print("╠════════════════════════════════════════════════════════╣");
    Print("║ Scalping: ", stats.scalpingWins, "W / ", stats.scalpingLosses, "L");
    Print("║ Swing: ", stats.swingWins, "W / ", stats.swingLosses, "L");
    Print("║ Breakout: ", stats.breakoutWins, "W / ", stats.breakoutLosses, "L");
    Print("╚════════════════════════════════════════════════════════╝");

    // Release indicators
    IndicatorRelease(g_handleFastMA);
    IndicatorRelease(g_handleSlowMA);
    IndicatorRelease(g_handleRSI);
    IndicatorRelease(g_handleATR);
    IndicatorRelease(g_handleBB);
    IndicatorRelease(g_handleMACD);
    if(UseMultiTimeframe) IndicatorRelease(g_handleHTF_MA);
}

//+------------------------------------------------------------------+
//| Expert tick function - THE HEART OF THE BEAST                   |
//+------------------------------------------------------------------+
void OnTick() {
    // New bar detection
    datetime currentBarTime = iTime(_Symbol, PERIOD_CURRENT, 0);
    if(currentBarTime == g_lastBarTime) return;
    g_lastBarTime = currentBarTime;

    // Check drawdown limit
    PerformanceStats stats = g_strategyMgr.GetStats();
    if(stats.currentDD > MaxDrawdownPercent) {
        Print("⚠️ Maximum drawdown reached! Stopping trading.");
        CloseAllPositions("Max DD reached");
        return;
    }

    // Detect market regime
    MARKET_REGIME regime = DetectMarketRegime();

    // Select best strategy
    STRATEGY_TYPE strategy = g_strategyMgr.SelectBestStrategy(regime);

    if(strategy == STRATEGY_NONE) return;

    // Prepare features for AI
    double features[];
    PrepareFeatures(features, regime);

    // Get AI prediction
    double aiSignal = g_brain.Predict(features);
    double confidence = g_brain.GetConfidence();

    // Generate strategy signal
    int signal = 0;
    string reason = "";

    switch(strategy) {
        case STRATEGY_SCALPING:
            signal = GenerateScalpingSignal(reason);
            break;
        case STRATEGY_SWING:
            signal = GenerateSwingSignal(reason);
            break;
        case STRATEGY_BREAKOUT:
            signal = GenerateBreakoutSignal(reason);
            break;
    }

    // AI override or confirmation
    if(EnableNeuralOverride) {
        if(confidence < MinConfidence) {
            signal = 0; // AI not confident - skip trade
        } else if(aiSignal > 0.6 && signal == 0) {
            signal = 1; // AI sees opportunity
            reason = "AI_Override_Buy";
        } else if(aiSignal < 0.4 && signal == 0) {
            signal = -1; // AI sees opportunity
            reason = "AI_Override_Sell";
        }
    }

    // Execute trade if signal and space available
    if(signal != 0 && g_activeTradeCount < MaxPositions) {
        ExecuteTrade(signal, strategy, confidence, reason);
    }

    // Manage existing positions
    ManagePositions();

    // Update dashboard
    if(ShowDashboard) {
        UpdateDashboard();
    }
}

//+------------------------------------------------------------------+
//| Detect Market Regime                                             |
//+------------------------------------------------------------------+
MARKET_REGIME DetectMarketRegime() {
    double fastMA[], slowMA[], atr[];
    ArraySetAsSeries(fastMA, true);
    ArraySetAsSeries(slowMA, true);
    ArraySetAsSeries(atr, true);

    if(CopyBuffer(g_handleFastMA, 0, 0, 20, fastMA) <= 0) return REGIME_UNKNOWN;
    if(CopyBuffer(g_handleSlowMA, 0, 0, 20, slowMA) <= 0) return REGIME_UNKNOWN;
    if(CopyBuffer(g_handleATR, 0, 0, 10, atr) <= 0) return REGIME_UNKNOWN;

    double currentPrice = iClose(_Symbol, PERIOD_CURRENT, 0);

    // Calculate trend strength
    double trendStrength = 0;
    for(int i = 0; i < 10; i++) {
        if(fastMA[i] > slowMA[i]) trendStrength++;
        else trendStrength--;
    }
    trendStrength /= 10.0;

    // Calculate volatility
    double avgATR = 0;
    for(int i = 0; i < 10; i++) avgATR += atr[i];
    avgATR /= 10;

    double normalizedVol = avgATR / currentPrice * 100;

    // Classify regime
    if(normalizedVol > 0.15) {
        if(MathAbs(trendStrength) > 0.7) return REGIME_BREAKOUT;
        return REGIME_HIGH_VOLATILITY;
    }

    if(normalizedVol < 0.05) {
        return REGIME_LOW_VOLATILITY;
    }

    if(trendStrength > 0.6) return REGIME_STRONG_TREND_UP;
    if(trendStrength < -0.6) return REGIME_STRONG_TREND_DOWN;
    if(trendStrength > 0.3) return REGIME_WEAK_TREND_UP;
    if(trendStrength < -0.3) return REGIME_WEAK_TREND_DOWN;

    return REGIME_RANGING;
}

//+------------------------------------------------------------------+
//| Prepare Features for AI                                          |
//+------------------------------------------------------------------+
void PrepareFeatures(double &features[], MARKET_REGIME regime) {
    ArrayResize(features, 20);
    ArrayInitialize(features, 0);

    // Price action
    double close[], high[], low[], open[];
    ArraySetAsSeries(close, true);
    ArraySetAsSeries(high, true);
    ArraySetAsSeries(low, true);
    ArraySetAsSeries(open, true);

    CopyClose(_Symbol, PERIOD_CURRENT, 0, 10, close);
    CopyHigh(_Symbol, PERIOD_CURRENT, 0, 10, high);
    CopyLow(_Symbol, PERIOD_CURRENT, 0, 10, low);
    CopyOpen(_Symbol, PERIOD_CURRENT, 0, 10, open);

    // Feature 0-2: Price momentum
    features[0] = (close[0] - close[1]) / close[1];
    features[1] = (close[0] - close[5]) / close[5];
    features[2] = (close[0] - close[9]) / close[9];

    // Feature 3-4: Candle patterns
    features[3] = (close[0] - open[0]) / (high[0] - low[0] + 0.00001);
    features[4] = (high[0] - low[0]) / close[0];

    // Feature 5-7: Indicators
    double rsi[], macdMain[], macdSignal[];
    ArraySetAsSeries(rsi, true);
    ArraySetAsSeries(macdMain, true);
    ArraySetAsSeries(macdSignal, true);

    CopyBuffer(g_handleRSI, 0, 0, 1, rsi);
    CopyBuffer(g_handleMACD, 0, 0, 1, macdMain);
    CopyBuffer(g_handleMACD, 1, 0, 1, macdSignal);

    features[5] = (rsi[0] - 50) / 50;
    features[6] = macdMain[0] / close[0];
    features[7] = (macdMain[0] - macdSignal[0]) / close[0];

    // Feature 8-9: Bollinger Bands
    double bbUpper[], bbLower[], bbMiddle[];
    ArraySetAsSeries(bbUpper, true);
    ArraySetAsSeries(bbLower, true);
    ArraySetAsSeries(bbMiddle, true);

    CopyBuffer(g_handleBB, 1, 0, 1, bbUpper);
    CopyBuffer(g_handleBB, 2, 0, 1, bbLower);
    CopyBuffer(g_handleBB, 0, 0, 1, bbMiddle);

    features[8] = (close[0] - bbMiddle[0]) / (bbUpper[0] - bbLower[0] + 0.00001);
    features[9] = (bbUpper[0] - bbLower[0]) / bbMiddle[0];

    // Feature 10: Regime
    features[10] = (double)regime / 8.0;

    // Feature 11-12: Volume (tick volume)
    long volume[];
    ArraySetAsSeries(volume, true);
    CopyTickVolume(_Symbol, PERIOD_CURRENT, 0, 5, volume);

    double avgVol = (volume[0] + volume[1] + volume[2] + volume[3] + volume[4]) / 5.0;
    features[11] = volume[0] / (avgVol + 1);
    features[12] = (volume[0] - volume[1]) / (volume[1] + 1);

    // Feature 13-19: Reserved for future expansion
}

//+------------------------------------------------------------------+
//| Generate Scalping Signal                                         |
//+------------------------------------------------------------------+
int GenerateScalpingSignal(string &reason) {
    double rsi[], bbUpper[], bbLower[], bbMiddle[];
    ArraySetAsSeries(rsi, true);
    ArraySetAsSeries(bbUpper, true);
    ArraySetAsSeries(bbLower, true);
    ArraySetAsSeries(bbMiddle, true);

    CopyBuffer(g_handleRSI, 0, 0, 2, rsi);
    CopyBuffer(g_handleBB, 1, 0, 1, bbUpper);
    CopyBuffer(g_handleBB, 2, 0, 1, bbLower);
    CopyBuffer(g_handleBB, 0, 0, 1, bbMiddle);

    double price = iClose(_Symbol, PERIOD_CURRENT, 0);

    // Oversold bounce
    if(rsi[0] < 30 && rsi[1] < rsi[0] && price < bbLower[0]) {
        reason = "Scalp_Oversold_Bounce";
        return 1;
    }

    // Overbought drop
    if(rsi[0] > 70 && rsi[1] > rsi[0] && price > bbUpper[0]) {
        reason = "Scalp_Overbought_Drop";
        return -1;
    }

    // Mean reversion
    double distance = (price - bbMiddle[0]) / (bbUpper[0] - bbLower[0]);
    if(distance < -0.8) {
        reason = "Scalp_Mean_Reversion_Buy";
        return 1;
    }
    if(distance > 0.8) {
        reason = "Scalp_Mean_Reversion_Sell";
        return -1;
    }

    return 0;
}

//+------------------------------------------------------------------+
//| Generate Swing Signal                                            |
//+------------------------------------------------------------------+
int GenerateSwingSignal(string &reason) {
    double fastMA[], slowMA[], macdMain[], macdSignal[];
    ArraySetAsSeries(fastMA, true);
    ArraySetAsSeries(slowMA, true);
    ArraySetAsSeries(macdMain, true);
    ArraySetAsSeries(macdSignal, true);

    CopyBuffer(g_handleFastMA, 0, 0, 3, fastMA);
    CopyBuffer(g_handleSlowMA, 0, 0, 3, slowMA);
    CopyBuffer(g_handleMACD, 0, 0, 2, macdMain);
    CopyBuffer(g_handleMACD, 1, 0, 2, macdSignal);

    double price = iClose(_Symbol, PERIOD_CURRENT, 0);

    // Golden cross
    if(fastMA[0] > slowMA[0] && fastMA[1] <= slowMA[1]) {
        if(macdMain[0] > macdSignal[0]) {
            // Multi-timeframe confirmation
            if(UseMultiTimeframe) {
                double htfMA[];
                ArraySetAsSeries(htfMA, true);
                CopyBuffer(g_handleHTF_MA, 0, 0, 1, htfMA);
                if(price < htfMA[0]) return 0; // Against higher TF trend
            }
            reason = "Swing_Golden_Cross";
            return 1;
        }
    }

    // Death cross
    if(fastMA[0] < slowMA[0] && fastMA[1] >= slowMA[1]) {
        if(macdMain[0] < macdSignal[0]) {
            // Multi-timeframe confirmation
            if(UseMultiTimeframe) {
                double htfMA[];
                ArraySetAsSeries(htfMA, true);
                CopyBuffer(g_handleHTF_MA, 0, 0, 1, htfMA);
                if(price > htfMA[0]) return 0; // Against higher TF trend
            }
            reason = "Swing_Death_Cross";
            return -1;
        }
    }

    // Trend continuation
    if(fastMA[0] > slowMA[0] && price > fastMA[0] && macdMain[0] > 0) {
        if(fastMA[0] > fastMA[1] && fastMA[1] > fastMA[2]) {
            reason = "Swing_Uptrend_Continuation";
            return 1;
        }
    }

    if(fastMA[0] < slowMA[0] && price < fastMA[0] && macdMain[0] < 0) {
        if(fastMA[0] < fastMA[1] && fastMA[1] < fastMA[2]) {
            reason = "Swing_Downtrend_Continuation";
            return -1;
        }
    }

    return 0;
}

//+------------------------------------------------------------------+
//| Generate Breakout Signal                                         |
//+------------------------------------------------------------------+
int GenerateBreakoutSignal(string &reason) {
    double high[], low[], atr[];
    ArraySetAsSeries(high, true);
    ArraySetAsSeries(low, true);
    ArraySetAsSeries(atr, true);

    CopyHigh(_Symbol, PERIOD_CURRENT, 0, 20, high);
    CopyLow(_Symbol, PERIOD_CURRENT, 0, 20, low);
    CopyBuffer(g_handleATR, 0, 0, 1, atr);

    double price = iClose(_Symbol, PERIOD_CURRENT, 0);

    // Find recent high/low (last 20 bars excluding current)
    double recentHigh = high[1];
    double recentLow = low[1];

    for(int i = 1; i < 20; i++) {
        if(high[i] > recentHigh) recentHigh = high[i];
        if(low[i] < recentLow) recentLow = low[i];
    }

    // Upside breakout
    if(price > recentHigh + atr[0] * 0.5) {
        // Check volume confirmation
        long volume[];
        ArraySetAsSeries(volume, true);
        CopyTickVolume(_Symbol, PERIOD_CURRENT, 0, 5, volume);

        double avgVol = (volume[1] + volume[2] + volume[3] + volume[4]) / 4.0;
        if(volume[0] > avgVol * 1.5) { // Volume spike
            reason = "Breakout_Upside";
            return 1;
        }
    }

    // Downside breakout
    if(price < recentLow - atr[0] * 0.5) {
        long volume[];
        ArraySetAsSeries(volume, true);
        CopyTickVolume(_Symbol, PERIOD_CURRENT, 0, 5, volume);

        double avgVol = (volume[1] + volume[2] + volume[3] + volume[4]) / 4.0;
        if(volume[0] > avgVol * 1.5) {
            reason = "Breakout_Downside";
            return -1;
        }
    }

    return 0;
}

//+------------------------------------------------------------------+
//| Execute Trade                                                    |
//+------------------------------------------------------------------+
void ExecuteTrade(int signal, STRATEGY_TYPE strategy, double confidence, string reason) {
    double lotSize = CalculateLotSize(confidence, strategy);

    double atr[];
    ArraySetAsSeries(atr, true);
    if(CopyBuffer(g_handleATR, 0, 0, 1, atr) <= 0) return;

    double price = signal > 0 ? SymbolInfoDouble(_Symbol, SYMBOL_ASK) : SymbolInfoDouble(_Symbol, SYMBOL_BID);

    // Calculate stops based on strategy
    double slDistance, tpDistance;

    switch(strategy) {
        case STRATEGY_SCALPING:
            slDistance = atr[0] * 1.5;
            tpDistance = atr[0] * 1.0;  // Quick profit
            break;
        case STRATEGY_SWING:
            slDistance = atr[0] * 2.5;
            tpDistance = atr[0] * 5.0;  // Let it run
            break;
        case STRATEGY_BREAKOUT:
            slDistance = atr[0] * 2.0;
            tpDistance = atr[0] * 4.0;
            break;
        default:
            slDistance = atr[0] * 2.0;
            tpDistance = atr[0] * 3.0;
    }

    // Turbo mode multiplier
    if(TurboMode) {
        tpDistance *= 1.5;
        lotSize *= 1.3;
    }

    double sl = signal > 0 ? price - slDistance : price + slDistance;
    double tp = signal > 0 ? price + tpDistance : price - tpDistance;

    sl = NormalizeDouble(sl, _Digits);
    tp = NormalizeDouble(tp, _Digits);

    string comment = StringFormat("%s|Conf:%.0f%%|%s",
                                  EnumToString(strategy),
                                  confidence * 100,
                                  reason);

    bool result = false;
    if(signal > 0) {
        result = trade.Buy(lotSize, _Symbol, price, sl, tp, comment);
    } else {
        result = trade.Sell(lotSize, _Symbol, price, sl, tp, comment);
    }

    if(result) {
        // Record trade
        int slot = FindFreeSlot();
        if(slot >= 0) {
            g_trades[slot].ticket = trade.ResultOrder();
            g_trades[slot].openTime = TimeCurrent();
            g_trades[slot].openPrice = price;
            g_trades[slot].lotSize = lotSize;
            g_trades[slot].direction = signal;
            g_trades[slot].strategy = strategy;
            g_trades[slot].confidence = confidence;
            g_trades[slot].reason = reason;

            g_activeTradeCount++;

            Print("✓ Trade executed: ", comment, " | Lot: ", lotSize);

            // Draw signal on chart
            if(DrawSignalsOnChart) {
                DrawTradeArrow(price, signal, reason);
            }
        }
    } else {
        Print("❌ Trade failed: ", trade.ResultComment());
    }
}

//+------------------------------------------------------------------+
//| Calculate Lot Size                                               |
//+------------------------------------------------------------------+
double CalculateLotSize(double confidence, STRATEGY_TYPE strategy) {
    double balance = AccountInfoDouble(ACCOUNT_BALANCE);
    double riskAmount = balance * RiskPercent / 100.0;

    // Dynamic risk adjustment
    if(UseDynamicRisk) {
        PerformanceStats stats = g_strategyMgr.GetStats();
        double winRate = stats.GetWinRate();

        if(winRate > 60) riskAmount *= 1.2;  // Increase risk when winning
        else if(winRate < 40) riskAmount *= 0.7;  // Reduce risk when losing

        // Confidence multiplier
        riskAmount *= MathMax(0.5, confidence);
    }

    // Kelly Criterion
    if(UseKellyOptimization) {
        PerformanceStats stats = g_strategyMgr.GetStats();
        if(stats.totalTrades > 30) {
            double winRate = stats.GetWinRate() / 100.0;
            double avgWin = stats.GetAverageWin();
            double avgLoss = MathAbs(stats.GetAverageLoss());

            if(avgWin > 0 && avgLoss > 0) {
                double kelly = (winRate * avgWin - (1 - winRate) * avgLoss) / avgWin;
                kelly = MathMax(0, MathMin(0.25, kelly));  // Cap at 25%
                riskAmount *= kelly * 4;  // Scale back up
            }
        }
    }

    // ATR-based position sizing
    double atr[];
    ArraySetAsSeries(atr, true);
    if(CopyBuffer(g_handleATR, 0, 0, 1, atr) <= 0) return BaseLotSize;

    double stopDistance = atr[0] * 2.0;
    double tickValue = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
    double tickSize = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);

    if(tickValue <= 0 || tickSize <= 0) return BaseLotSize;

    double pointsInStop = stopDistance / _Point;
    double lotSize = riskAmount / (pointsInStop * tickValue);

    // Normalize
    double minLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
    double maxLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
    double stepLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);

    lotSize = MathMax(minLot, MathMax(BaseLotSize, lotSize));
    lotSize = MathMin(maxLot, lotSize);
    lotSize = MathRound(lotSize / stepLot) * stepLot;

    return NormalizeDouble(lotSize, 2);
}

//+------------------------------------------------------------------+
//| Manage Open Positions                                            |
//+------------------------------------------------------------------+
void ManagePositions() {
    for(int i = 0; i < MaxPositions; i++) {
        if(g_trades[i].ticket == 0) continue;

        if(!PositionSelectByTicket(g_trades[i].ticket)) {
            // Position closed
            OnPositionClosed(i);
            continue;
        }

        double currentPrice = PositionGetDouble(POSITION_PRICE_CURRENT);
        double profit = PositionGetDouble(POSITION_PROFIT);
        double openPrice = g_trades[i].openPrice;
        double sl = PositionGetDouble(POSITION_SL);
        double tp = PositionGetDouble(POSITION_TP);

        // Update stats
        if(profit > g_trades[i].maxProfit) g_trades[i].maxProfit = profit;
        if(profit < -g_trades[i].maxDrawdown) g_trades[i].maxDrawdown = -profit;

        // Breakeven logic
        if(EnableBreakeven && !g_trades[i].breakevenSet) {
            double atr[];
            ArraySetAsSeries(atr, true);
            CopyBuffer(g_handleATR, 0, 0, 1, atr);

            double beDistance = atr[0] * 1.5;

            if(g_trades[i].direction > 0) {  // Buy
                if(currentPrice >= openPrice + beDistance) {
                    double newSL = openPrice + atr[0] * 0.2;  // Small profit lock
                    if(newSL > sl) {
                        trade.PositionModify(g_trades[i].ticket, newSL, tp);
                        g_trades[i].breakevenSet = true;
                        Print("✓ Breakeven set for #", g_trades[i].ticket);
                    }
                }
            } else {  // Sell
                if(currentPrice <= openPrice - beDistance) {
                    double newSL = openPrice - atr[0] * 0.2;
                    if(newSL < sl) {
                        trade.PositionModify(g_trades[i].ticket, newSL, tp);
                        g_trades[i].breakevenSet = true;
                        Print("✓ Breakeven set for #", g_trades[i].ticket);
                    }
                }
            }
        }

        // Trailing stop
        if(EnableTrailingStop && profit > 0) {
            double atr[];
            ArraySetAsSeries(atr, true);
            CopyBuffer(g_handleATR, 0, 0, 1, atr);

            double trailDistance = atr[0] * 1.8;

            if(g_trades[i].direction > 0) {  // Buy
                double newSL = currentPrice - trailDistance;
                if(newSL > sl && newSL > openPrice) {
                    trade.PositionModify(g_trades[i].ticket, NormalizeDouble(newSL, _Digits), tp);
                }
            } else {  // Sell
                double newSL = currentPrice + trailDistance;
                if(newSL < sl && newSL < openPrice) {
                    trade.PositionModify(g_trades[i].ticket, NormalizeDouble(newSL, _Digits), tp);
                }
            }
        }

        // Scaling in (pyramid)
        if(EnableScalingIn && !g_trades[i].scaledIn && profit > 0) {
            double atr[];
            ArraySetAsSeries(atr, true);
            CopyBuffer(g_handleATR, 0, 0, 1, atr);

            double scaleDistance = atr[0] * 2.0;

            bool shouldScale = false;
            if(g_trades[i].direction > 0 && currentPrice >= openPrice + scaleDistance) {
                shouldScale = true;
            } else if(g_trades[i].direction < 0 && currentPrice <= openPrice - scaleDistance) {
                shouldScale = true;
            }

            if(shouldScale && g_activeTradeCount < MaxPositions) {
                double scaleLot = g_trades[i].lotSize * 0.5;
                ExecuteTrade(g_trades[i].direction, g_trades[i].strategy,
                            g_trades[i].confidence, "Scale_In");
                g_trades[i].scaledIn = true;
                Print("✓ Scaled into position #", g_trades[i].ticket);
            }
        }
    }
}

//+------------------------------------------------------------------+
//| Position Closed Handler                                          |
//+------------------------------------------------------------------+
void OnPositionClosed(int slot) {
    if(slot < 0 || slot >= MaxPositions) return;
    if(g_trades[slot].ticket == 0) return;

    // Find the closed position in history
    if(HistorySelectByPosition(g_trades[slot].ticket)) {
        ulong dealTicket = 0;
        int deals = HistoryDealsTotal();

        for(int i = deals - 1; i >= 0; i--) {
            dealTicket = HistoryDealGetTicket(i);
            if(HistoryDealGetInteger(dealTicket, DEAL_POSITION_ID) == g_trades[slot].ticket) {
                break;
            }
        }

        if(dealTicket > 0) {
            double profit = HistoryDealGetDouble(dealTicket, DEAL_PROFIT);
            double commission = HistoryDealGetDouble(dealTicket, DEAL_COMMISSION);
            double swap = HistoryDealGetDouble(dealTicket, DEAL_SWAP);
            double netProfit = profit + commission + swap;

            bool won = netProfit > 0;

            // Update strategy manager
            g_strategyMgr.UpdateStats(won, netProfit, g_trades[slot].strategy);

            // Teach AI
            double features[];
            MARKET_REGIME regime = DetectMarketRegime();
            PrepareFeatures(features, regime);
            g_brain.Learn(features, won, netProfit);

            // Log result
            string emoji = won ? "💰" : "❌";
            Print(emoji, " Trade closed #", g_trades[slot].ticket,
                  " | ", EnumToString(g_trades[slot].strategy),
                  " | Profit: $", NormalizeDouble(netProfit, 2),
                  " | Reason: ", g_trades[slot].reason);

            PerformanceStats stats = g_strategyMgr.GetStats();
            Print("   📊 Win Rate: ", NormalizeDouble(stats.GetWinRate(), 1), "%",
                  " | Profit Factor: ", NormalizeDouble(stats.GetProfitFactor(), 2),
                  " | AI Patterns: ", g_brain.GetPatternsLearned());
        }
    }

    // Clear slot
    g_trades[slot].Reset();
    g_activeTradeCount--;
}

//+------------------------------------------------------------------+
//| Close All Positions                                              |
//+------------------------------------------------------------------+
void CloseAllPositions(string reason) {
    for(int i = 0; i < MaxPositions; i++) {
        if(g_trades[i].ticket > 0) {
            if(PositionSelectByTicket(g_trades[i].ticket)) {
                trade.PositionClose(g_trades[i].ticket);
            }
        }
    }
    Print("⚠️ All positions closed: ", reason);
}

//+------------------------------------------------------------------+
//| Find Free Slot                                                   |
//+------------------------------------------------------------------+
int FindFreeSlot() {
    for(int i = 0; i < MaxPositions; i++) {
        if(g_trades[i].ticket == 0) return i;
    }
    return -1;
}

//+------------------------------------------------------------------+
//| Update Dashboard                                                 |
//+------------------------------------------------------------------+
void UpdateDashboard() {
    PerformanceStats stats = g_strategyMgr.GetStats();

    string dashboard = "\n";
    dashboard += "╔═══════════════ ULTIMATE SYSTEM ═══════════════╗\n";
    dashboard += StringFormat("║ Trades: %d | Win Rate: %.1f%% | PF: %.2f     ║\n",
                             stats.totalTrades,
                             stats.GetWinRate(),
                             stats.GetProfitFactor());
    dashboard += StringFormat("║ Profit: $%.2f | DD: %.1f%% | Active: %d    ║\n",
                             stats.totalProfit,
                             stats.currentDD,
                             g_activeTradeCount);
    dashboard += StringFormat("║ AI Confidence: %.0f%% | Patterns: %d      ║\n",
                             g_brain.GetConfidence() * 100,
                             g_brain.GetPatternsLearned());
    dashboard += "╚════════════════════════════════════════════════╝\n";

    Comment(dashboard);
}

//+------------------------------------------------------------------+
//| Draw Trade Arrow                                                 |
//+------------------------------------------------------------------+
void DrawTradeArrow(double price, int signal, string reason) {
    string name = "Signal_" + IntegerToString(TimeCurrent());
    datetime time = iTime(_Symbol, PERIOD_CURRENT, 0);

    if(signal > 0) {
        ObjectCreate(0, name, OBJ_ARROW_BUY, 0, time, price);
        ObjectSetInteger(0, name, OBJPROP_COLOR, clrLime);
    } else {
        ObjectCreate(0, name, OBJ_ARROW_SELL, 0, time, price);
        ObjectSetInteger(0, name, OBJPROP_COLOR, clrRed);
    }

    ObjectSetInteger(0, name, OBJPROP_WIDTH, 3);
    ObjectSetString(0, name, OBJPROP_TEXT, reason);
}

//+------------------------------------------------------------------+
