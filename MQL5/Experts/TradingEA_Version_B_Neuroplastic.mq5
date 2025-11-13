//+------------------------------------------------------------------+
//|                      TradingEA_Version_B_Neuroplastic.mq5       |
//|                    Production-Grade Adaptive Trading System     |
//|                        Neuroplastic Architecture v3.00          |
//+------------------------------------------------------------------+
#property copyright "Neuroplastic Trading Framework v3.0"
#property version   "3.00"
#property strict
#property description "Advanced neuroplastic trading system with defensive architecture"

#include <Trade\Trade.mqh>
#include <Math\Stat\Math.mqh>
#include "../Include/NeuroplasticTradingBrain_Complete.mqh"

//+------------------------------------------------------------------+
//| Input Parameters with validation ranges                         |
//+------------------------------------------------------------------+
input group "Risk Management"
input double RiskPercent = 1.0;           // Risk per trade (%) [0.1-5.0]
input double MaxDrawdownPercent = 20.0;   // Maximum drawdown (%) [5.0-50.0]
input bool   UseKellyCriterion = true;    // Use Kelly position sizing

input group "Neural Control"
input bool   UseNeuralOverride = true;    // Allow brain to override signals
input int    LearningPeriod = 50;         // Trades before full activation [10-200]
input double MinConfidence = 0.6;         // Minimum confidence to trade [0.3-0.9]

input group "Trading Settings"
input int    MagicNumber = 271025;        // Unique identifier
input double BaseLotSize = 0.01;          // Base position size [0.01-1.0]
input int    MaxPositions = 1;            // Maximum simultaneous positions [1-5]
input int    SlippagePoints = 10;         // Maximum slippage [5-50]

input group "Market Analysis"
input int    RegimeWindow = 100;          // Bars for regime detection [50-200]
input int    ATRPeriod = 14;              // ATR period [7-21]
input bool   TradeInTransitions = false;  // Trade during regime transitions

input group "Diagnostics"
input bool   EnableDiagnostics = true;    // Output performance metrics
input int    DiagnosticInterval = 300;    // Seconds between reports [60-3600]

//+------------------------------------------------------------------+
//| Validation and safety constants                                 |
//+------------------------------------------------------------------+
#define SYSTEM_VERSION      "3.0.0"
#define MIN_BARS_REQUIRED   200
#define MAX_SPREAD_POINTS   50
#define PROFIT_CACHE_SIZE   100
#define STATE_FILE_PREFIX   "NeuroplasticEA_"

//+------------------------------------------------------------------+
//| Market Regime Enumeration                                       |
//+------------------------------------------------------------------+
enum MARKET_REGIME {
    REGIME_TRENDING_BULL,
    REGIME_TRENDING_BEAR,
    REGIME_RANGING,
    REGIME_VOLATILE,
    REGIME_QUIET,
    REGIME_TRANSITIONING,
    REGIME_UNKNOWN
};

//+------------------------------------------------------------------+
//| Trade Management Structure                                      |
//+------------------------------------------------------------------+
struct ActiveTrade {
    ulong    ticket;
    datetime entryTime;
    double   entryPrice;
    double   volume;
    int      direction;
    double   maxProfit;
    double   maxDrawdown;
    string   entryPattern;
    double   entryConfidence;
    double   stopLoss;
    double   takeProfit;
    int      barsInTrade;

    void Reset() {
        ticket = 0;
        entryTime = 0;
        entryPrice = 0;
        volume = 0;
        direction = 0;
        maxProfit = 0;
        maxDrawdown = 0;
        entryPattern = "";
        entryConfidence = 0;
        stopLoss = 0;
        takeProfit = 0;
        barsInTrade = 0;
    }
};

//+------------------------------------------------------------------+
//| Main EA Class with defensive architecture                       |
//+------------------------------------------------------------------+
class CNeuroplasticEA {
private:
    CTrade            m_trade;
    MARKET_REGIME     m_currentRegime;
    MARKET_REGIME     m_previousRegime;
    ActiveTrade       m_trades[];
    int               m_activeTradeCount;

    // Performance tracking
    int               m_totalTrades;
    int               m_winningTrades;
    double            m_totalProfit;
    double            m_peakBalance;
    double            m_currentDrawdown;
    double            m_maxDrawdown;
    double            m_profitHistory[];

    // Market data buffers
    double            m_priceBuffer[];
    double            m_volumeBuffer[];
    double            m_volatilityBuffer[];
    double            m_spreadBuffer[];

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
    string            m_stateFile;

    bool ValidateInputs() {
        bool valid = true;

        if(RiskPercent < 0.1 || RiskPercent > 5.0) {
            Print("ERROR: RiskPercent must be between 0.1 and 5.0");
            valid = false;
        }

        if(MaxDrawdownPercent < 5.0 || MaxDrawdownPercent > 50.0) {
            Print("ERROR: MaxDrawdownPercent must be between 5.0 and 50.0");
            valid = false;
        }

        if(LearningPeriod < 10 || LearningPeriod > 200) {
            Print("ERROR: LearningPeriod must be between 10 and 200");
            valid = false;
        }

        if(MinConfidence < 0.3 || MinConfidence > 0.9) {
            Print("ERROR: MinConfidence must be between 0.3 and 0.9");
            valid = false;
        }

        if(BaseLotSize < 0.01 || BaseLotSize > 1.0) {
            Print("ERROR: BaseLotSize must be between 0.01 and 1.0");
            valid = false;
        }

        if(RegimeWindow < 50 || RegimeWindow > 200) {
            Print("ERROR: RegimeWindow must be between 50 and 200");
            valid = false;
        }

        return valid;
    }

public:
    bool ValidateEnvironment() {
        if(SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE) <= 0) {
            Print("ERROR: Invalid tick value for symbol ", _Symbol);
            return false;
        }

        if(SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE) <= 0) {
            Print("ERROR: Invalid tick size for symbol ", _Symbol);
            return false;
        }

        if(!TerminalInfoInteger(TERMINAL_TRADE_ALLOWED)) {
            Print("ERROR: Trading not allowed in terminal");
            return false;
        }

        if(!MQLInfoInteger(MQL_TRADE_ALLOWED)) {
            Print("ERROR: Automated trading not allowed");
            return false;
        }

        if(AccountInfoDouble(ACCOUNT_BALANCE) <= 0) {
            Print("ERROR: Invalid account balance");
            return false;
        }

        int bars = Bars(_Symbol, PERIOD_CURRENT);
        if(bars < MIN_BARS_REQUIRED) {
            Print("ERROR: Insufficient bars. Need ", MIN_BARS_REQUIRED, ", have ", bars);
            return false;
        }

        return true;
    }

    CNeuroplasticEA() {
        m_initialized = false;
        m_barsSinceStart = 0;
        m_lastBarTime = 0;
        m_stateFile = STATE_FILE_PREFIX + _Symbol + "_" + IntegerToString(MagicNumber) + ".dat";

        if(!ValidateInputs()) {
            Print("FATAL: Input validation failed");
            return;
        }

        ArrayResize(m_trades, MaxPositions);
        ArrayResize(m_priceBuffer, RegimeWindow);
        ArrayResize(m_volumeBuffer, RegimeWindow);
        ArrayResize(m_volatilityBuffer, RegimeWindow);
        ArrayResize(m_spreadBuffer, RegimeWindow);
        ArrayResize(m_profitHistory, PROFIT_CACHE_SIZE);

        ArrayInitialize(m_priceBuffer, 0);
        ArrayInitialize(m_volumeBuffer, 0);
        ArrayInitialize(m_volatilityBuffer, 0);
        ArrayInitialize(m_spreadBuffer, 0);
        ArrayInitialize(m_profitHistory, 0);

        for(int i = 0; i < MaxPositions; i++) {
            m_trades[i].Reset();
        }

        m_trade.SetExpertMagicNumber(MagicNumber);
        m_trade.SetDeviationInPoints(SlippagePoints);
        m_trade.SetTypeFilling(GetFillingMode());
        m_trade.SetAsyncMode(false);

        m_currentRegime = REGIME_UNKNOWN;
        m_previousRegime = REGIME_UNKNOWN;
        m_activeTradeCount = 0;
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

        LoadState();

        m_initialized = true;
    }

    ~CNeuroplasticEA() {
        if(m_initialized) {
            SaveState();

            if(m_atrHandle != INVALID_HANDLE) IndicatorRelease(m_atrHandle);
            if(m_rsiHandle != INVALID_HANDLE) IndicatorRelease(m_rsiHandle);
            if(m_macdHandle != INVALID_HANDLE) IndicatorRelease(m_macdHandle);
            if(m_bbHandle != INVALID_HANDLE) IndicatorRelease(m_bbHandle);
            if(m_maHandle != INVALID_HANDLE) IndicatorRelease(m_maHandle);
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
            Print("Failed to create indicators");
            return false;
        }

        return true;
    }

    void OnTick() {
        if(!m_initialized) return;

        datetime currentBarTime = iTime(_Symbol, PERIOD_CURRENT, 0);
        bool isNewBar = (currentBarTime != m_lastBarTime);

        if(isNewBar) {
            m_lastBarTime = currentBarTime;
            m_barsSinceStart++;

            if(m_barsSinceStart < RegimeWindow) {
                return;
            }
        }

        UpdateDrawdown();
        if(m_currentDrawdown > MaxDrawdownPercent / 100.0) {
            Print("Maximum drawdown reached: ", NormalizeDouble(m_currentDrawdown * 100, 2), "%");
            CloseAllPositions("Max drawdown");
            return;
        }

        long spread = SymbolInfoInteger(_Symbol, SYMBOL_SPREAD);
        if(spread > MAX_SPREAD_POINTS) {
            if(EnableDiagnostics) {
                Print("Spread too high: ", spread, " points");
            }
            return;
        }

        DetectMarketRegime();

        if(!TradeInTransitions && m_currentRegime == REGIME_TRANSITIONING) {
            return;
        }

        double features[];
        if(!PrepareFeatures(features)) {
            return;
        }

        int brainSignal = GetBrainSignal(features, m_currentDrawdown);
        double confidence = GetBrainConfidence();

        int traditionalSignal = GenerateTraditionalSignal();

        int finalSignal = 0;
        double finalConfidence = confidence;

        if(m_totalTrades < LearningPeriod) {
            finalSignal = traditionalSignal;
            finalConfidence *= 0.3;
        }
        else if(UseNeuralOverride) {
            if(brainSignal != 0 && confidence >= MinConfidence) {
                finalSignal = brainSignal;
            }
            else if(traditionalSignal == brainSignal) {
                finalSignal = brainSignal;
                finalConfidence = MathMin(1.0, confidence * 1.2);
            }
            else {
                finalSignal = (confidence > 0.7) ? brainSignal : 0;
            }
        }
        else {
            finalSignal = traditionalSignal;
            finalConfidence = 0.5;
        }

        if(finalSignal != 0 && m_activeTradeCount < MaxPositions) {
            if(CanTrade()) {
                ExecuteTrade(finalSignal, finalConfidence);
            }
        }

        ManageOpenPositions();
    }

    void DetectMarketRegime() {
        if(ArraySize(m_priceBuffer) < RegimeWindow) {
            ArrayResize(m_priceBuffer, RegimeWindow);
            ArrayResize(m_volumeBuffer, RegimeWindow);
            ArrayResize(m_volatilityBuffer, RegimeWindow);
            ArrayResize(m_spreadBuffer, RegimeWindow);
        }

        for(int i = RegimeWindow - 1; i > 0; i--) {
            m_priceBuffer[i] = m_priceBuffer[i-1];
            m_volumeBuffer[i] = m_volumeBuffer[i-1];
            m_volatilityBuffer[i] = m_volatilityBuffer[i-1];
            m_spreadBuffer[i] = m_spreadBuffer[i-1];
        }

        m_priceBuffer[0] = iClose(_Symbol, PERIOD_CURRENT, 0);
        m_volumeBuffer[0] = (double)iVolume(_Symbol, PERIOD_CURRENT, 0);
        m_spreadBuffer[0] = (double)SymbolInfoInteger(_Symbol, SYMBOL_SPREAD);

        double atr[];
        ArraySetAsSeries(atr, true);
        if(CopyBuffer(m_atrHandle, 0, 0, 1, atr) > 0 && atr[0] > 0) {
            m_volatilityBuffer[0] = atr[0];
        } else {
            m_volatilityBuffer[0] = MathAbs(iHigh(_Symbol, PERIOD_CURRENT, 0) -
                                           iLow(_Symbol, PERIOD_CURRENT, 0));
        }

        if(m_barsSinceStart < RegimeWindow) {
            m_currentRegime = REGIME_UNKNOWN;
            return;
        }

        if(m_priceBuffer[0] <= 0 || m_priceBuffer[RegimeWindow-1] <= 0) {
            return;
        }

        double priceChange = SafeDivide(m_priceBuffer[0] - m_priceBuffer[RegimeWindow-1],
                                        m_priceBuffer[RegimeWindow-1]);
        double volatilityMean = CalculateMean(m_volatilityBuffer, RegimeWindow);
        double volatilityStd = CalculateStdDev(m_volatilityBuffer, RegimeWindow);

        double pointValue = _Point;
        if(pointValue <= 0) pointValue = 0.00001;
        double normalizedVolatility = SafeDivide(volatilityMean, pointValue * 1000);

        m_previousRegime = m_currentRegime;

        if(normalizedVolatility > 2.0) {
            m_currentRegime = REGIME_VOLATILE;
        }
        else if(normalizedVolatility < 0.5) {
            m_currentRegime = REGIME_QUIET;
        }
        else if(MathAbs(priceChange) > 0.01) {
            m_currentRegime = (priceChange > 0) ? REGIME_TRENDING_BULL : REGIME_TRENDING_BEAR;
        }
        else {
            m_currentRegime = REGIME_RANGING;
        }

        if(m_previousRegime != REGIME_UNKNOWN &&
           m_previousRegime != m_currentRegime &&
           m_previousRegime != REGIME_TRANSITIONING) {

            MARKET_REGIME newRegime = m_currentRegime;
            m_currentRegime = REGIME_TRANSITIONING;

            if(EnableDiagnostics) {
                Print("Regime transition: ", EnumToString(m_previousRegime),
                      " -> ", EnumToString(newRegime));
            }
        }
    }

    bool PrepareFeatures(double &features[]) {
        ArrayResize(features, 20);
        ArrayInitialize(features, 0);

        double close0 = iClose(_Symbol, PERIOD_CURRENT, 0);
        double close1 = iClose(_Symbol, PERIOD_CURRENT, 1);
        double high0 = iHigh(_Symbol, PERIOD_CURRENT, 0);
        double low0 = iLow(_Symbol, PERIOD_CURRENT, 0);

        if(close0 <= 0 || close1 <= 0) return false;

        features[0] = NormalizePrice(close0 - close1);
        features[1] = NormalizePrice(high0 - low0);

        features[2] = NormalizeVolume(iVolume(_Symbol, PERIOD_CURRENT, 0));
        features[3] = NormalizeVolume(iVolume(_Symbol, PERIOD_CURRENT, 1));

        double rsi[];
        ArraySetAsSeries(rsi, true);
        if(CopyBuffer(m_rsiHandle, 0, 0, 1, rsi) > 0) {
            features[4] = (rsi[0] - 50) / 50;
        }

        double macdMain[], macdSignal[];
        ArraySetAsSeries(macdMain, true);
        ArraySetAsSeries(macdSignal, true);
        if(CopyBuffer(m_macdHandle, 0, 0, 1, macdMain) > 0 &&
           CopyBuffer(m_macdHandle, 1, 0, 1, macdSignal) > 0) {
            features[5] = NormalizePrice(macdMain[0]);
            features[6] = NormalizePrice(macdMain[0] - macdSignal[0]);
        }

        double upper[], lower[], middle[];
        ArraySetAsSeries(upper, true);
        ArraySetAsSeries(lower, true);
        ArraySetAsSeries(middle, true);

        if(CopyBuffer(m_bbHandle, 1, 0, 1, upper) > 0 &&
           CopyBuffer(m_bbHandle, 2, 0, 1, lower) > 0 &&
           CopyBuffer(m_bbHandle, 0, 0, 1, middle) > 0) {

            double bbWidth = upper[0] - lower[0];
            if(bbWidth > 0) {
                features[7] = SafeDivide(close0 - middle[0], bbWidth);
                features[8] = SafeDivide(bbWidth, middle[0]);
            }
        }

        features[9] = (double)m_currentRegime / 6.0;

        for(int i = 0; i < 10; i++) {
            double c1 = iClose(_Symbol, PERIOD_CURRENT, i);
            double c2 = iClose(_Symbol, PERIOD_CURRENT, i + 1);
            if(c1 > 0 && c2 > 0) {
                features[10 + i] = NormalizePrice(c1 - c2);
            }
        }

        return true;
    }

    int GenerateTraditionalSignal() {
        double rsi[], macdMain[], macdSignal[];
        double upper[], lower[], middle[], ma[];

        ArraySetAsSeries(rsi, true);
        ArraySetAsSeries(macdMain, true);
        ArraySetAsSeries(macdSignal, true);
        ArraySetAsSeries(upper, true);
        ArraySetAsSeries(lower, true);
        ArraySetAsSeries(middle, true);
        ArraySetAsSeries(ma, true);

        if(CopyBuffer(m_rsiHandle, 0, 0, 1, rsi) <= 0) return 0;
        if(CopyBuffer(m_macdHandle, 0, 0, 1, macdMain) <= 0) return 0;
        if(CopyBuffer(m_macdHandle, 1, 0, 1, macdSignal) <= 0) return 0;
        if(CopyBuffer(m_bbHandle, 0, 0, 1, middle) <= 0) return 0;
        if(CopyBuffer(m_bbHandle, 1, 0, 1, upper) <= 0) return 0;
        if(CopyBuffer(m_bbHandle, 2, 0, 1, lower) <= 0) return 0;
        if(CopyBuffer(m_maHandle, 0, 0, 1, ma) <= 0) return 0;

        double currentPrice = iClose(_Symbol, PERIOD_CURRENT, 0);

        if(rsi[0] < 40 &&
           macdMain[0] > macdSignal[0] &&
           currentPrice > ma[0] &&
           currentPrice < middle[0] &&
           m_currentRegime != REGIME_TRENDING_BEAR) {
            return 1;
        }

        if(rsi[0] > 60 &&
           macdMain[0] < macdSignal[0] &&
           currentPrice < ma[0] &&
           currentPrice > middle[0] &&
           m_currentRegime != REGIME_TRENDING_BULL) {
            return -1;
        }

        return 0;
    }

    bool CanTrade() {
        if(!TerminalInfoInteger(TERMINAL_CONNECTED)) {
            Print("No connection to server");
            return false;
        }

        if(!MQLInfoInteger(MQL_TRADE_ALLOWED)) {
            return false;
        }

        double freeMargin = AccountInfoDouble(ACCOUNT_MARGIN_FREE);
        double requiredMargin = SymbolInfoDouble(_Symbol, SYMBOL_MARGIN_INITIAL) * BaseLotSize;

        if(freeMargin < requiredMargin * 2) {
            Print("Insufficient margin");
            return false;
        }

        return true;
    }

    void ExecuteTrade(int signal, double confidence) {
        double lotSize = CalculatePositionSize(confidence);

        double minLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
        double maxLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);

        if(lotSize < minLot) {
            if(EnableDiagnostics) {
                Print("Position too small: ", lotSize);
            }
            return;
        }

        if(lotSize > maxLot) {
            lotSize = maxLot;
        }

        double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
        double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
        double price = (signal > 0) ? ask : bid;

        double atr[];
        ArraySetAsSeries(atr, true);
        if(CopyBuffer(m_atrHandle, 0, 0, 1, atr) <= 0) return;

        double atrMultiplier = (m_currentRegime == REGIME_VOLATILE) ? 3.0 : 2.0;
        double stopDistance = atr[0] * atrMultiplier;
        double tpDistance = stopDistance * 2.0;

        double minStopDistance = SymbolInfoInteger(_Symbol, SYMBOL_TRADE_STOPS_LEVEL) * _Point;
        stopDistance = MathMax(stopDistance, minStopDistance * 1.5);
        tpDistance = MathMax(tpDistance, minStopDistance * 2);

        double sl, tp;
        string comment = StringFormat("NeuroB_%s_%.2f",
                                     (signal > 0 ? "Buy" : "Sell"),
                                     confidence);

        bool result = false;

        if(signal > 0) {
            sl = NormalizeDouble(price - stopDistance, _Digits);
            tp = NormalizeDouble(price + tpDistance, _Digits);
            result = m_trade.Buy(lotSize, _Symbol, price, sl, tp, comment);
        }
        else {
            sl = NormalizeDouble(price + stopDistance, _Digits);
            tp = NormalizeDouble(price - tpDistance, _Digits);
            result = m_trade.Sell(lotSize, _Symbol, price, sl, tp, comment);
        }

        if(result) {
            int slot = FindFreeTradeSlot();
            if(slot >= 0) {
                m_trades[slot].ticket = m_trade.ResultOrder();
                m_trades[slot].entryTime = TimeCurrent();
                m_trades[slot].entryPrice = price;
                m_trades[slot].volume = lotSize;
                m_trades[slot].direction = signal;
                m_trades[slot].entryPattern = GetCurrentPattern();
                m_trades[slot].entryConfidence = confidence;
                m_trades[slot].stopLoss = sl;
                m_trades[slot].takeProfit = tp;
                m_trades[slot].maxProfit = 0;
                m_trades[slot].maxDrawdown = 0;
                m_trades[slot].barsInTrade = 0;

                m_activeTradeCount++;
                m_totalTrades++;

                if(EnableDiagnostics) {
                    Print(comment, ": ", lotSize, " lots at ", price,
                          " SL=", sl, " TP=", tp);
                }
            }
        }
        else {
            Print("Trade failed: ", m_trade.ResultComment());
        }
    }

    double CalculatePositionSize(double confidence) {
        double balance = AccountInfoDouble(ACCOUNT_BALANCE);
        if(balance <= 0) return 0;

        double riskAmount = balance * RiskPercent / 100.0;

        switch(m_currentRegime) {
            case REGIME_VOLATILE:
                riskAmount *= 0.5;
                break;
            case REGIME_TRENDING_BULL:
            case REGIME_TRENDING_BEAR:
                riskAmount *= 1.2;
                break;
            case REGIME_QUIET:
                riskAmount *= 0.8;
                break;
            case REGIME_TRANSITIONING:
                riskAmount *= 0.3;
                break;
            case REGIME_UNKNOWN:
                riskAmount *= 0.2;
                break;
        }

        riskAmount *= MathMax(0.1, confidence);

        if(UseKellyCriterion && m_totalTrades > 30 && m_winningTrades > 0) {
            double winRate = (double)m_winningTrades / m_totalTrades;
            double avgWin = MathAbs(m_totalProfit / m_winningTrades);
            double lossCount = m_totalTrades - m_winningTrades;
            double avgLoss = lossCount > 0 ?
                            MathAbs((m_totalProfit - avgWin * m_winningTrades) / lossCount) :
                            avgWin;

            if(avgWin > 0 && avgLoss > 0) {
                double kellyFraction = (winRate * avgWin - (1 - winRate) * avgLoss) / avgWin;
                kellyFraction = MathMax(0, MathMin(0.25, kellyFraction));
                riskAmount *= kellyFraction * 4;
            }
        }

        double atr[];
        ArraySetAsSeries(atr, true);
        if(CopyBuffer(m_atrHandle, 0, 0, 1, atr) <= 0 || atr[0] <= 0) {
            atr[0] = SymbolInfoDouble(_Symbol, SYMBOL_BID) * 0.001;
        }

        double stopDistance = atr[0] * 2.0;
        double tickValue = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
        double tickSize = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);

        if(tickValue <= 0 || tickSize <= 0) {
            if(EnableDiagnostics) {
                Print("Warning: Invalid tick parameters");
            }
            return BaseLotSize;
        }

        double pointsInStop = SafeDivide(stopDistance, _Point);
        if(pointsInStop <= 0) pointsInStop = 100;

        double lotSize = SafeDivide(riskAmount, pointsInStop * tickValue);

        double minLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
        double maxLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
        double stepLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);

        if(minLot <= 0) minLot = 0.01;
        if(maxLot <= 0) maxLot = 100.0;
        if(stepLot <= 0) stepLot = 0.01;

        lotSize = MathMax(MathMax(BaseLotSize, minLot), lotSize);
        lotSize = MathMin(maxLot, lotSize);
        lotSize = MathRound(lotSize / stepLot) * stepLot;

        return NormalizeDouble(lotSize, 2);
    }

    void ManageOpenPositions() {
        for(int i = 0; i < MaxPositions; i++) {
            if(m_trades[i].ticket == 0) continue;

            if(!PositionSelectByTicket(m_trades[i].ticket)) {
                OnTradeClose(i);
                continue;
            }

            double currentPrice = PositionGetDouble(POSITION_PRICE_CURRENT);
            double openPrice = PositionGetDouble(POSITION_PRICE_OPEN);
            double profit = PositionGetDouble(POSITION_PROFIT);
            double sl = PositionGetDouble(POSITION_SL);

            if(profit > m_trades[i].maxProfit) {
                m_trades[i].maxProfit = profit;
            }
            if(profit < -m_trades[i].maxDrawdown) {
                m_trades[i].maxDrawdown = -profit;
            }

            m_trades[i].barsInTrade++;

            double atr[];
            ArraySetAsSeries(atr, true);
            if(CopyBuffer(m_atrHandle, 0, 0, 1, atr) <= 0) continue;

            double trailDistance = atr[0] * ((m_currentRegime == REGIME_VOLATILE) ? 3.0 : 2.0);

            if(m_trades[i].direction > 0) {
                double newSL = currentPrice - trailDistance;
                if(newSL > sl && newSL > openPrice) {
                    m_trade.PositionModify(m_trades[i].ticket,
                                          NormalizeDouble(newSL, _Digits),
                                          PositionGetDouble(POSITION_TP));
                }
            }
            else {
                double newSL = currentPrice + trailDistance;
                if(newSL < sl && newSL < openPrice) {
                    m_trade.PositionModify(m_trades[i].ticket,
                                          NormalizeDouble(newSL, _Digits),
                                          PositionGetDouble(POSITION_TP));
                }
            }

            if(m_currentRegime == REGIME_TRANSITIONING && profit > 0) {
                m_trade.PositionClose(m_trades[i].ticket);
                OnTradeClose(i);
            }
        }
    }

    void OnTradeClose(int index) {
        if(index < 0 || index >= MaxPositions) return;
        if(m_trades[index].ticket == 0) return;

        if(HistorySelectByPosition(m_trades[index].ticket)) {
            ulong dealTicket = 0;
            int dealsTotal = HistoryDealsTotal();

            for(int i = dealsTotal - 1; i >= 0; i--) {
                dealTicket = HistoryDealGetTicket(i);
                if(HistoryDealGetInteger(dealTicket, DEAL_POSITION_ID) == m_trades[index].ticket) {
                    break;
                }
            }

            if(dealTicket > 0) {
                double profit = HistoryDealGetDouble(dealTicket, DEAL_PROFIT);
                double commission = HistoryDealGetDouble(dealTicket, DEAL_COMMISSION);
                double swap = HistoryDealGetDouble(dealTicket, DEAL_SWAP);
                double exitPrice = HistoryDealGetDouble(dealTicket, DEAL_PRICE);

                double netProfit = profit + commission + swap;

                if(netProfit > 0) m_winningTrades++;
                m_totalProfit += netProfit;

                int histIdx = m_totalTrades % PROFIT_CACHE_SIZE;
                m_profitHistory[histIdx] = netProfit;

                TeachBrain(m_trades[index].entryTime,
                          m_trades[index].entryPrice,
                          exitPrice,
                          m_trades[index].volume,
                          m_trades[index].direction,
                          netProfit,
                          m_trades[index].maxDrawdown);

                if(EnableDiagnostics) {
                    Print("Trade closed. Profit: ", NormalizeDouble(netProfit, 2),
                          " Win rate: ", NormalizeDouble((double)m_winningTrades/m_totalTrades * 100, 1), "%");
                }
            }
        }

        m_trades[index].Reset();
        m_activeTradeCount--;
    }

    void UpdateDrawdown() {
        double balance = AccountInfoDouble(ACCOUNT_BALANCE);
        double equity = AccountInfoDouble(ACCOUNT_EQUITY);

        if(balance > m_peakBalance) {
            m_peakBalance = balance;
        }

        m_currentDrawdown = SafeDivide(m_peakBalance - equity, m_peakBalance);

        if(m_currentDrawdown > m_maxDrawdown) {
            m_maxDrawdown = m_currentDrawdown;
        }
    }

    void CloseAllPositions(string reason) {
        for(int i = 0; i < MaxPositions; i++) {
            if(m_trades[i].ticket > 0) {
                if(PositionSelectByTicket(m_trades[i].ticket)) {
                    m_trade.PositionClose(m_trades[i].ticket);
                }
            }
        }
        Print("All positions closed: ", reason);
    }

    void SaveState() {
        int handle = FileOpen(m_stateFile, FILE_WRITE|FILE_BIN);
        if(handle != INVALID_HANDLE) {
            FileWriteString(handle, SYSTEM_VERSION);
            FileWriteInteger(handle, m_totalTrades);
            FileWriteInteger(handle, m_winningTrades);
            FileWriteDouble(handle, m_totalProfit);
            FileWriteDouble(handle, m_peakBalance);
            FileWriteDouble(handle, m_maxDrawdown);

            FileClose(handle);
        }
    }

    void LoadState() {
        if(!FileIsExist(m_stateFile)) return;

        int handle = FileOpen(m_stateFile, FILE_READ|FILE_BIN);
        if(handle != INVALID_HANDLE) {
            string version = FileReadString(handle);

            if(version == SYSTEM_VERSION) {
                m_totalTrades = FileReadInteger(handle);
                m_winningTrades = FileReadInteger(handle);
                m_totalProfit = FileReadDouble(handle);
                m_peakBalance = FileReadDouble(handle);
                m_maxDrawdown = FileReadDouble(handle);

                Print("State restored. Total trades: ", m_totalTrades);
            }

            FileClose(handle);
        }
    }

    string GetPerformanceReport() {
        double winRate = m_totalTrades > 0 ?
                        (double)m_winningTrades / m_totalTrades * 100 : 0;
        double avgProfit = m_totalTrades > 0 ?
                          m_totalProfit / m_totalTrades : 0;

        return StringFormat(
            "=== Performance Report ===\n" +
            "Trades: %d | Win Rate: %.1f%%\n" +
            "Total Profit: %.2f | Avg: %.2f\n" +
            "Max DD: %.1f%% | Current DD: %.1f%%\n" +
            "Regime: %s | Active: %d/%d\n" +
            "Brain Confidence: %.1f%%",
            m_totalTrades, winRate,
            m_totalProfit, avgProfit,
            m_maxDrawdown * 100, m_currentDrawdown * 100,
            EnumToString(m_currentRegime),
            m_activeTradeCount, MaxPositions,
            GetBrainConfidence() * 100
        );
    }

    int FindFreeTradeSlot() {
        for(int i = 0; i < MaxPositions; i++) {
            if(m_trades[i].ticket == 0) return i;
        }
        return -1;
    }

    ENUM_ORDER_TYPE_FILLING GetFillingMode() {
        int filling = (int)SymbolInfoInteger(_Symbol, SYMBOL_FILLING_MODE);

        if((filling & SYMBOL_FILLING_FOK) == SYMBOL_FILLING_FOK) {
            return ORDER_FILLING_FOK;
        }
        if((filling & SYMBOL_FILLING_IOC) == SYMBOL_FILLING_IOC) {
            return ORDER_FILLING_IOC;
        }

        return ORDER_FILLING_RETURN;
    }

    string GetCurrentPattern() {
        switch(m_currentRegime) {
            case REGIME_TRENDING_BULL: return "bull_trend";
            case REGIME_TRENDING_BEAR: return "bear_trend";
            case REGIME_VOLATILE: return "volatile";
            case REGIME_QUIET: return "quiet";
            case REGIME_TRANSITIONING: return "transition";
            case REGIME_RANGING: return "ranging";
            default: return "unknown";
        }
    }

    double NormalizePrice(double price) {
        if(_Point <= 0) return 0;
        return SafeDivide(price, _Point * 100);
    }

    double NormalizeVolume(double volume) {
        return SafeDivide(volume, 10000.0);
    }

    double CalculateMean(double &array[], int count) {
        int size = MathMin(count, ArraySize(array));
        if(size <= 0) return 0;

        double sum = 0;
        int validCount = 0;

        for(int i = 0; i < size; i++) {
            if(MathIsValidNumber(array[i])) {
                sum += array[i];
                validCount++;
            }
        }

        return validCount > 0 ? sum / validCount : 0;
    }

    double CalculateStdDev(double &array[], int count) {
        int size = MathMin(count, ArraySize(array));
        if(size <= 2) return 0;

        double mean = CalculateMean(array, count);
        double sum = 0;
        int validCount = 0;

        for(int i = 0; i < size; i++) {
            if(MathIsValidNumber(array[i])) {
                sum += MathPow(array[i] - mean, 2);
                validCount++;
            }
        }

        return validCount > 1 ? MathSqrt(sum / (validCount - 1)) : 0;
    }

    double SafeDivide(double numerator, double denominator) {
        if(MathAbs(denominator) < 0.0000001) return 0;
        return numerator / denominator;
    }

    // Public accessors for reporting
    int GetTotalTrades() const { return m_totalTrades; }
    int GetWinningTrades() const { return m_winningTrades; }
    double GetTotalProfit() const { return m_totalProfit; }
    double GetMaxDrawdown() const { return m_maxDrawdown; }
};

//+------------------------------------------------------------------+
//| Global Variables                                                |
//+------------------------------------------------------------------+
CNeuroplasticEA* g_EA = NULL;
int g_diagnosticTimer = 0;

//+------------------------------------------------------------------+
//| Expert initialization                                           |
//+------------------------------------------------------------------+
int OnInit() {
    Print("=================================================");
    Print("Neuroplastic Trading Brain v", SYSTEM_VERSION, " INITIALIZING");
    Print("Symbol: ", _Symbol, " | Timeframe: ", EnumToString(PERIOD_CURRENT));

    CNeuroplasticEA tempEA;
    if(!tempEA.ValidateEnvironment()) {
        Print("FATAL: Environment validation failed");
        return INIT_FAILED;
    }

    if(!InitializeNeuroplasticBrain()) {
        Print("FATAL: Brain initialization failed");
        return INIT_FAILED;
    }

    g_EA = new CNeuroplasticEA();
    if(g_EA == NULL) {
        Print("FATAL: EA initialization failed");
        CleanupBrain();
        return INIT_FAILED;
    }

    if(EnableDiagnostics && DiagnosticInterval > 0) {
        EventSetTimer(1);
    }

    Print("Regime Detection: ONLINE");
    Print("Neural Modules: SYNCHRONIZED");
    Print("Memory Banks: INITIALIZED");
    Print("Synaptic Plasticity: ENGAGED");
    Print("Safety Systems: ACTIVE");
    Print("Test Mode: ", MQLInfoInteger(MQL_TESTER) ? "YES" : "NO");
    Print("=================================================");

    return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| Expert deinitialization                                         |
//+------------------------------------------------------------------+
void OnDeinit(const int reason) {
    EventKillTimer();

    if(g_EA != NULL) {
        if(EnableDiagnostics) {
            Print(g_EA.GetPerformanceReport());
        }
        delete g_EA;
        g_EA = NULL;
    }

    CleanupBrain();

    Print("Neuroplastic Trading Brain shutdown. Reason: ", reason);
    Print("Neural pathways saved. System hibernating.");
}

//+------------------------------------------------------------------+
//| Expert tick function                                            |
//+------------------------------------------------------------------+
void OnTick() {
    if(g_EA != NULL) {
        g_EA.OnTick();
    }
}

//+------------------------------------------------------------------+
//| Timer event for diagnostics                                    |
//+------------------------------------------------------------------+
void OnTimer() {
    if(!EnableDiagnostics) return;

    g_diagnosticTimer++;

    if(g_diagnosticTimer >= DiagnosticInterval) {
        g_diagnosticTimer = 0;

        if(g_EA != NULL) {
            Print(g_EA.GetPerformanceReport());
            Print(GetBrainDiagnostics());
        }
    }
}

//+------------------------------------------------------------------+
//| Tester function for optimization                               |
//+------------------------------------------------------------------+
double OnTester() {
    if(g_EA == NULL) return 0;

    double totalTrades = g_EA.GetTotalTrades();
    if(totalTrades < 30) return 0;

    double winRate = (double)g_EA.GetWinningTrades() / totalTrades;
    double avgProfit = g_EA.GetTotalProfit() / totalTrades;
    double maxDD = g_EA.GetMaxDrawdown();

    double performance = (winRate * avgProfit) / MathMax(0.01, maxDD);

    return performance;
}

//+------------------------------------------------------------------+
