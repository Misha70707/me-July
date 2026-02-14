//+------------------------------------------------------------------+
//|                                     TradingEA_Version_D_TRM.mq5 |
//|                        Copyright 2023, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2023, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"

#include <Trade\Trade.mqh>
#include <TinyRecursiveUnit.mqh>

input int InpReasoningSteps = 6;       // n: Inner loop depth (Reasoning)
input int InpRefinementCycles = 2;     // T: Outer loop cycles (Refinement)
input double InpSignalThreshold = 0.6; // Confidence threshold
input double InpLotSize = 0.1;

CTrade trade;
CTRM trm;
int handleRSI, handleMA, handleATR;
datetime lastBarTime = 0;

// Features:
// 0: RSI (normalized 0-1)
// 1: MA Distance (Close - MA) / MA
// 2: ATR (normalized by Close)
// 3: High-Low Range (normalized by ATR)
// 4: Close-Open Body (normalized by ATR)
const int INPUT_DIM = 5;
const int LATENT_DIM = 16; // "Tiny" latent space
const int OUTPUT_DIM = 3;  // 0: Buy, 1: Sell, 2: Hold

int OnInit() {
    // Initialize Indicators
    handleRSI = iRSI(_Symbol, PERIOD_CURRENT, 14, PRICE_CLOSE);
    handleMA = iMA(_Symbol, PERIOD_CURRENT, 50, 0, MODE_SMA, PRICE_CLOSE);
    handleATR = iATR(_Symbol, PERIOD_CURRENT, 14);

    if(handleRSI == INVALID_HANDLE || handleMA == INVALID_HANDLE || handleATR == INVALID_HANDLE) {
        Print("Failed to create indicator handles");
        return INIT_FAILED;
    }

    // Seed Random Generator for Demo Weights
    MathSrand(GetTickCount());

    // Initialize TRM (Random weights for demo)
    // In a real scenario, you would load weights here: trm.LoadWeights("weights.bin");
    trm.Init(INPUT_DIM, LATENT_DIM, OUTPUT_DIM, InpReasoningSteps, InpRefinementCycles);

    Print("TRM Initialized: Input=", INPUT_DIM, " Latent=", LATENT_DIM, " Output=", OUTPUT_DIM);

    return INIT_SUCCEEDED;
}

void OnDeinit(const int reason) {
    IndicatorRelease(handleRSI);
    IndicatorRelease(handleMA);
    IndicatorRelease(handleATR);
}

void OnTick() {
    // 1. New Bar Check (Zenith Standard: Don't choke OnTick)
    // Only run the heavy TRM logic once per bar
    datetime currentBarTime = iTime(_Symbol, PERIOD_CURRENT, 0);
    if(lastBarTime == currentBarTime) return;
    lastBarTime = currentBarTime;

    // 2. Feature Extraction (Efficient buffers)
    // Using dynamic arrays for CopyBuffer compatibility (MQL5 requires dynamic arrays)
    double rsi[], ma[], atr[];
    MqlRates rates[];

    // Set as series to ensure index 0 is the requested bar
    ArraySetAsSeries(rsi, true);
    ArraySetAsSeries(ma, true);
    ArraySetAsSeries(atr, true);
    ArraySetAsSeries(rates, true);

    // Fetch data for the LAST CLOSED bar (index 1) to ensure stability
    // Note: Since we fetch count=1 starting from index 1, the result array will have size 1
    // and the value will be at index 0 of the result array.
    if(CopyBuffer(handleRSI, 0, 1, 1, rsi) < 1) return;
    if(CopyBuffer(handleMA, 0, 1, 1, ma) < 1) return;
    if(CopyBuffer(handleATR, 0, 1, 1, atr) < 1) return;
    if(CopyRates(_Symbol, PERIOD_CURRENT, 1, 1, rates) < 1) return;

    // Prepare Input Vector (Feature Engineering)
    vectorf x(INPUT_DIM);
    double close = rates[0].close;
    double open = rates[0].open;
    double high = rates[0].high;
    double low = rates[0].low;
    double volatility = (atr[0] > 0) ? atr[0] : 1.0;

    x[0] = (float)(rsi[0] / 100.0);                           // RSI [0,1]
    x[1] = (float)((close - ma[0]) / ma[0]);                  // MA Distance
    x[2] = (float)(volatility / close);                       // Volatility Ratio
    x[3] = (float)((high - low) / volatility);                // Normalized Range
    x[4] = (float)((close - open) / volatility);              // Normalized Body

    // 3. Think (TRM Execution)
    // The "Think-Loop" runs here: Recursive Reasoning -> Refinement
    vectorf y = trm.Think(x);

    // 4. Trade Logic
    // y[0] = Buy, y[1] = Sell, y[2] = Hold
    // MGU outputs are tanh activated [-1, 1]
    float buy_conf = y[0];
    float sell_conf = y[1];
    float hold_conf = y[2];

    // Simple logic: Trigger if signal is dominant and above threshold
    if(buy_conf > InpSignalThreshold && buy_conf > sell_conf && buy_conf > hold_conf) {
        if(PositionsTotal() == 0) {
            trade.Buy(InpLotSize, _Symbol);
            Print("TRM Buy Signal: ", buy_conf);
        }
    }
    else if(sell_conf > InpSignalThreshold && sell_conf > buy_conf && sell_conf > hold_conf) {
        if(PositionsTotal() == 0) {
            trade.Sell(InpLotSize, _Symbol);
            Print("TRM Sell Signal: ", sell_conf);
        }
    }
}
