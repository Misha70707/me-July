//+------------------------------------------------------------------+
//|                             TradingEA_Version_A_Traditional.mq5 |
//|                         Traditional Layered Architecture        |
//|                              Version 1.0                        |
//+------------------------------------------------------------------+
#property copyright "Traditional Trading Framework v1.0"
#property version   "1.00"
#property strict
#property description "Traditional indicator-based trading system with basic neural layer"

#include <Trade\Trade.mqh>

//+------------------------------------------------------------------+
//| Input Parameters                                                 |
//+------------------------------------------------------------------+
input group "Risk Management"
input double RiskPercent = 1.0;           // Risk per trade (%)
input double MaxDrawdownPercent = 20.0;   // Maximum drawdown (%)
input double StopLossATR = 2.0;           // Stop loss in ATR multiplier
input double TakeProfitATR = 3.0;         // Take profit in ATR multiplier

input group "Trading Settings"
input int    MagicNumber = 100001;        // Unique identifier
input double BaseLotSize = 0.01;          // Base position size
input int    MaxPositions = 1;            // Maximum simultaneous positions

input group "Indicator Settings"
input int    FastMA = 12;                 // Fast MA period
input int    SlowMA = 26;                 // Slow MA period
input int    RSI_Period = 14;             // RSI period
input int    RSI_Overbought = 70;         // RSI overbought level
input int    RSI_Oversold = 30;           // RSI oversold level
input int    ATRPeriod = 14;              // ATR period
input int    BB_Period = 20;              // Bollinger Bands period
input double BB_Deviation = 2.0;          // Bollinger Bands deviation

input group "Signal Settings"
input double MinSignalStrength = 0.6;     // Minimum signal strength (0-1)
input bool   UseMultiTimeframe = false;   // Use multi-timeframe analysis

//+------------------------------------------------------------------+
//| Global Variables                                                 |
//+------------------------------------------------------------------+
CTrade trade;
datetime lastBarTime = 0;
int totalTrades = 0;
int winningTrades = 0;
double peakBalance = 0;
double currentDrawdown = 0;

// Indicator handles
int handleFastMA;
int handleSlowMA;
int handleRSI;
int handleATR;
int handleBB;

// Simple neural weights (for signal combination)
double neuralWeights[5] = {0.25, 0.20, 0.20, 0.20, 0.15}; // MA, RSI, MACD, BB, Trend
double learningRate = 0.01;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit() {
    Print("========================================");
    Print("Traditional EA Version A Initializing");
    Print("Symbol: ", _Symbol);
    Print("========================================");

    // Initialize trade
    trade.SetExpertMagicNumber(MagicNumber);
    trade.SetDeviationInPoints(10);
    trade.SetTypeFilling(ORDER_FILLING_FOK);

    // Initialize indicators
    handleFastMA = iMA(_Symbol, PERIOD_CURRENT, FastMA, 0, MODE_EMA, PRICE_CLOSE);
    handleSlowMA = iMA(_Symbol, PERIOD_CURRENT, SlowMA, 0, MODE_EMA, PRICE_CLOSE);
    handleRSI = iRSI(_Symbol, PERIOD_CURRENT, RSI_Period, PRICE_CLOSE);
    handleATR = iATR(_Symbol, PERIOD_CURRENT, ATRPeriod);
    handleBB = iBands(_Symbol, PERIOD_CURRENT, BB_Period, 0, BB_Deviation, PRICE_CLOSE);

    if(handleFastMA == INVALID_HANDLE || handleSlowMA == INVALID_HANDLE ||
       handleRSI == INVALID_HANDLE || handleATR == INVALID_HANDLE ||
       handleBB == INVALID_HANDLE) {
        Print("ERROR: Failed to initialize indicators");
        return INIT_FAILED;
    }

    peakBalance = AccountInfoDouble(ACCOUNT_BALANCE);

    Print("Initialization successful");
    return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason) {
    Print("========================================");
    Print("Traditional EA Version A Shutting Down");
    Print("Total Trades: ", totalTrades);
    Print("Win Rate: ", (totalTrades > 0 ? NormalizeDouble((double)winningTrades/totalTrades*100, 2) : 0), "%");
    Print("========================================");

    IndicatorRelease(handleFastMA);
    IndicatorRelease(handleSlowMA);
    IndicatorRelease(handleRSI);
    IndicatorRelease(handleATR);
    IndicatorRelease(handleBB);
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick() {
    // New bar detection
    datetime currentBarTime = iTime(_Symbol, PERIOD_CURRENT, 0);
    if(currentBarTime == lastBarTime) return;
    lastBarTime = currentBarTime;

    // Update drawdown
    UpdateDrawdown();

    // Check maximum drawdown
    if(currentDrawdown > MaxDrawdownPercent / 100.0) {
        Print("Maximum drawdown reached: ", NormalizeDouble(currentDrawdown * 100, 2), "%");
        CloseAllPositions();
        return;
    }

    // Check if we can trade
    if(PositionsTotal() >= MaxPositions) return;

    // Generate trading signal
    double signalStrength = 0;
    int signal = GenerateTradingSignal(signalStrength);

    // Execute trade if signal is strong enough
    if(signal != 0 && signalStrength >= MinSignalStrength) {
        ExecuteTrade(signal, signalStrength);
    }

    // Manage open positions
    ManagePositions();
}

//+------------------------------------------------------------------+
//| Generate trading signal using multiple indicators                |
//+------------------------------------------------------------------+
int GenerateTradingSignal(double &strength) {
    double signals[5] = {0, 0, 0, 0, 0};

    // Get indicator values
    double fastMA[], slowMA[], rsi[], atr[], bbUpper[], bbLower[], bbMiddle[];
    ArraySetAsSeries(fastMA, true);
    ArraySetAsSeries(slowMA, true);
    ArraySetAsSeries(rsi, true);
    ArraySetAsSeries(atr, true);
    ArraySetAsSeries(bbUpper, true);
    ArraySetAsSeries(bbLower, true);
    ArraySetAsSeries(bbMiddle, true);

    if(CopyBuffer(handleFastMA, 0, 0, 3, fastMA) <= 0) return 0;
    if(CopyBuffer(handleSlowMA, 0, 0, 3, slowMA) <= 0) return 0;
    if(CopyBuffer(handleRSI, 0, 0, 3, rsi) <= 0) return 0;
    if(CopyBuffer(handleATR, 0, 0, 1, atr) <= 0) return 0;
    if(CopyBuffer(handleBB, 1, 0, 1, bbUpper) <= 0) return 0;
    if(CopyBuffer(handleBB, 2, 0, 1, bbLower) <= 0) return 0;
    if(CopyBuffer(handleBB, 0, 0, 1, bbMiddle) <= 0) return 0;

    double currentPrice = iClose(_Symbol, PERIOD_CURRENT, 0);

    // Signal 1: Moving Average Crossover
    if(fastMA[0] > slowMA[0] && fastMA[1] <= slowMA[1]) {
        signals[0] = 1.0;  // Bullish
    } else if(fastMA[0] < slowMA[0] && fastMA[1] >= slowMA[1]) {
        signals[0] = -1.0; // Bearish
    } else if(fastMA[0] > slowMA[0]) {
        signals[0] = 0.5;  // Weak bullish
    } else {
        signals[0] = -0.5; // Weak bearish
    }

    // Signal 2: RSI
    if(rsi[0] < RSI_Oversold) {
        signals[1] = 1.0;  // Oversold - Buy
    } else if(rsi[0] > RSI_Overbought) {
        signals[1] = -1.0; // Overbought - Sell
    } else if(rsi[0] < 50) {
        signals[1] = MathAbs(rsi[0] - 50) / 20.0; // Scaled bearish
    } else {
        signals[1] = -(MathAbs(rsi[0] - 50) / 20.0); // Scaled bullish
    }

    // Signal 3: MACD-like (using MAs)
    double macd = fastMA[0] - slowMA[0];
    double macdPrev = fastMA[1] - slowMA[1];
    if(macd > 0 && macdPrev <= 0) {
        signals[2] = 1.0;  // Bullish crossover
    } else if(macd < 0 && macdPrev >= 0) {
        signals[2] = -1.0; // Bearish crossover
    } else {
        signals[2] = macd > 0 ? 0.3 : -0.3;
    }

    // Signal 4: Bollinger Bands
    if(currentPrice < bbLower[0]) {
        signals[3] = 1.0;  // Price below lower band - Buy
    } else if(currentPrice > bbUpper[0]) {
        signals[3] = -1.0; // Price above upper band - Sell
    } else {
        double bbPosition = (currentPrice - bbMiddle[0]) / (bbUpper[0] - bbMiddle[0]);
        signals[3] = -bbPosition; // Normalized position
    }

    // Signal 5: Trend Strength (using price vs MAs)
    if(currentPrice > fastMA[0] && fastMA[0] > slowMA[0]) {
        signals[4] = 1.0;  // Strong uptrend
    } else if(currentPrice < fastMA[0] && fastMA[0] < slowMA[0]) {
        signals[4] = -1.0; // Strong downtrend
    } else {
        signals[4] = 0;    // No clear trend
    }

    // Combine signals using neural weights
    double combinedSignal = 0;
    for(int i = 0; i < 5; i++) {
        combinedSignal += signals[i] * neuralWeights[i];
    }

    // Calculate signal strength
    strength = MathAbs(combinedSignal);

    // Determine direction
    if(combinedSignal > 0.1) return 1;   // Buy
    if(combinedSignal < -0.1) return -1; // Sell
    return 0; // No signal
}

//+------------------------------------------------------------------+
//| Execute trade                                                    |
//+------------------------------------------------------------------+
void ExecuteTrade(int signal, double confidence) {
    double atr[];
    ArraySetAsSeries(atr, true);
    if(CopyBuffer(handleATR, 0, 0, 1, atr) <= 0) return;

    double lotSize = CalculateLotSize(atr[0]);

    double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
    double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);

    double sl, tp;
    bool result = false;

    if(signal > 0) {
        // Buy
        sl = NormalizeDouble(ask - atr[0] * StopLossATR, _Digits);
        tp = NormalizeDouble(ask + atr[0] * TakeProfitATR, _Digits);
        result = trade.Buy(lotSize, _Symbol, ask, sl, tp,
                          StringFormat("TradA_Buy_%.2f", confidence));
    } else {
        // Sell
        sl = NormalizeDouble(bid + atr[0] * StopLossATR, _Digits);
        tp = NormalizeDouble(bid - atr[0] * TakeProfitATR, _Digits);
        result = trade.Sell(lotSize, _Symbol, bid, sl, tp,
                           StringFormat("TradA_Sell_%.2f", confidence));
    }

    if(result) {
        totalTrades++;
        Print("Trade opened: ", (signal > 0 ? "BUY" : "SELL"),
              " | Confidence: ", NormalizeDouble(confidence, 2),
              " | Lot: ", lotSize);
    } else {
        Print("Trade failed: ", trade.ResultComment());
    }
}

//+------------------------------------------------------------------+
//| Calculate position size                                          |
//+------------------------------------------------------------------+
double CalculateLotSize(double atr) {
    double balance = AccountInfoDouble(ACCOUNT_BALANCE);
    double riskAmount = balance * RiskPercent / 100.0;

    double stopDistance = atr * StopLossATR;
    double tickValue = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
    double tickSize = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);

    if(tickValue <= 0 || tickSize <= 0 || stopDistance <= 0) {
        return BaseLotSize;
    }

    double pointsInStop = stopDistance / _Point;
    double lotSize = riskAmount / (pointsInStop * tickValue);

    // Normalize
    double minLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
    double maxLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
    double stepLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);

    lotSize = MathMax(minLot, lotSize);
    lotSize = MathMin(maxLot, lotSize);
    lotSize = MathRound(lotSize / stepLot) * stepLot;

    return NormalizeDouble(lotSize, 2);
}

//+------------------------------------------------------------------+
//| Manage open positions                                            |
//+------------------------------------------------------------------+
void ManagePositions() {
    for(int i = PositionsTotal() - 1; i >= 0; i--) {
        if(PositionSelectByTicket(PositionGetTicket(i))) {
            if(PositionGetInteger(POSITION_MAGIC) != MagicNumber) continue;
            if(PositionGetString(POSITION_SYMBOL) != _Symbol) continue;

            double profit = PositionGetDouble(POSITION_PROFIT);

            // Simple trailing stop
            double atr[];
            ArraySetAsSeries(atr, true);
            if(CopyBuffer(handleATR, 0, 0, 1, atr) > 0) {
                double currentPrice = PositionGetDouble(POSITION_PRICE_CURRENT);
                double openPrice = PositionGetDouble(POSITION_PRICE_OPEN);
                double sl = PositionGetDouble(POSITION_SL);
                double tp = PositionGetDouble(POSITION_TP);

                int posType = (int)PositionGetInteger(POSITION_TYPE);

                if(posType == POSITION_TYPE_BUY && profit > 0) {
                    double newSL = currentPrice - atr[0] * StopLossATR;
                    if(newSL > sl && newSL > openPrice) {
                        trade.PositionModify(PositionGetTicket(i),
                                            NormalizeDouble(newSL, _Digits), tp);
                    }
                } else if(posType == POSITION_TYPE_SELL && profit > 0) {
                    double newSL = currentPrice + atr[0] * StopLossATR;
                    if(newSL < sl && newSL < openPrice) {
                        trade.PositionModify(PositionGetTicket(i),
                                            NormalizeDouble(newSL, _Digits), tp);
                    }
                }
            }
        }
    }
}

//+------------------------------------------------------------------+
//| Update drawdown tracking                                         |
//+------------------------------------------------------------------+
void UpdateDrawdown() {
    double balance = AccountInfoDouble(ACCOUNT_BALANCE);
    double equity = AccountInfoDouble(ACCOUNT_EQUITY);

    if(balance > peakBalance) {
        peakBalance = balance;
    }

    currentDrawdown = (peakBalance - equity) / peakBalance;
}

//+------------------------------------------------------------------+
//| Close all positions                                              |
//+------------------------------------------------------------------+
void CloseAllPositions() {
    for(int i = PositionsTotal() - 1; i >= 0; i--) {
        if(PositionSelectByTicket(PositionGetTicket(i))) {
            if(PositionGetInteger(POSITION_MAGIC) == MagicNumber) {
                trade.PositionClose(PositionGetTicket(i));
            }
        }
    }
}

//+------------------------------------------------------------------+
//| Trade event handler                                              |
//+------------------------------------------------------------------+
void OnTrade() {
    // Update win rate when trades close
    if(HistoryDealsTotal() > 0) {
        ulong ticket = HistoryDealGetTicket(HistoryDealsTotal() - 1);
        if(HistoryDealGetInteger(ticket, DEAL_MAGIC) == MagicNumber) {
            double profit = HistoryDealGetDouble(ticket, DEAL_PROFIT);
            if(profit > 0) winningTrades++;

            // Simple learning: adjust weights based on result
            LearnFromTrade(profit > 0);
        }
    }
}

//+------------------------------------------------------------------+
//| Simple learning function                                         |
//+------------------------------------------------------------------+
void LearnFromTrade(bool wasWinning) {
    // Adjust neural weights slightly based on outcome
    double adjustment = learningRate * (wasWinning ? 1 : -1);

    for(int i = 0; i < 5; i++) {
        neuralWeights[i] += adjustment * (MathRand() / 32768.0 - 0.5) * 0.1;
        neuralWeights[i] = MathMax(0.1, MathMin(0.4, neuralWeights[i]));
    }

    // Normalize weights
    double sum = 0;
    for(int i = 0; i < 5; i++) sum += neuralWeights[i];
    for(int i = 0; i < 5; i++) neuralWeights[i] /= sum;
}

//+------------------------------------------------------------------+
