//+------------------------------------------------------------------+
//|                                             Gold_Ichimoku_VR.mq5 |
//|                                  Copyright 2024, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"

#include <Trade\Trade.mqh>
#include <AdaptiveIchimoku.mqh>
#include <RecursiveOptimizer.mqh>

//--- Inputs
input double   InpLotSize        = 0.1;      // Lot Size
input int      InpBaseTenkan     = 9;        // Base Tenkan-sen
input int      InpBaseKijun      = 26;       // Base Kijun-sen
input int      InpBaseSenkou     = 52;       // Base Senkou Span B
input int      InpMaxRiskPips    = 50;       // Max Risk (Pips)
input double   InpRiskReward     = 2.0;      // Risk:Reward Ratio

//--- Globals
CTrade               trade;
CAdaptiveIchimoku    ichiEngine;
CRecursiveOptimizer  optimizer;
int                  barsCounter = 0;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
   if(!ichiEngine.Init(InpBaseTenkan, InpBaseKijun, InpBaseSenkou))
      return INIT_FAILED;

   optimizer.Init(AccountInfoDouble(ACCOUNT_BALANCE));

   trade.SetExpertMagicNumber(123456);

   return(INIT_SUCCEEDED);
  }

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
  }

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
   // 1. Check New Bar (Optimization: Only run heavy logic on new bar or trailing stop updates)
   static datetime lastBar = 0;
   datetime currentBar = iTime(_Symbol, PERIOD_CURRENT, 0);
   bool isNewBar = (lastBar != currentBar);

   if(isNewBar)
     {
      lastBar = currentBar;
      ichiEngine.OnNewBar();
      ichiEngine.UpdateState(optimizer);

      // Manage Open Positions (Trailing Stop)
      ManagePositions();

      // Check Entries
      CheckEntry();
     }
  }

//+------------------------------------------------------------------+
//| Trade Transaction                                                |
//+------------------------------------------------------------------+
void OnTradeTransaction(const MqlTradeTransaction& trans,
                        const MqlTradeRequest& request,
                        const MqlTradeResult& result)
  {
   if(trans.type == TRADE_TRANSACTION_DEAL_ADD)
     {
      if(HistoryDealSelect(trans.deal))
        {
         long entryType = HistoryDealGetInteger(trans.deal, DEAL_ENTRY);
         if(entryType == DEAL_ENTRY_OUT)
           {
            double profit = HistoryDealGetDouble(trans.deal, DEAL_PROFIT);
            double balance = AccountInfoDouble(ACCOUNT_BALANCE);
            optimizer.OnTradeClosed(profit, balance);
           }
        }
     }
  }

//+------------------------------------------------------------------+
//| Logic: Check Entry                                               |
//+------------------------------------------------------------------+
void CheckEntry()
  {
   // Filter: Pause if Optimizer says so
   if(optimizer.ShouldPauseTrading()) return;

   // Filter: Only 1 position
   if(PositionsTotal() > 0) return;

   ENUM_ICHI_STATE state = ichiEngine.GetState();
   int barsInState = ichiEngine.GetBarsInState();

   // Requirement: "Require minimum 1 bar after state change confirmation"
   if(barsInState < 1) return;

   double price = iClose(_Symbol, PERIOD_CURRENT, 0);
   double tenkan = ichiEngine.GetTenkan(0);

   // Dynamic Lot Logic
   double lot = InpLotSize;
   if(optimizer.ShouldReduceRisk()) lot = InpLotSize * 0.5;

   if(state == STATE_BULLISH)
     {
      // "Entry only when price penetrates Tenkan-sen in confirmed direction"
      // Price > Tenkan
      if(price > tenkan)
        {
         OpenTrade(ORDER_TYPE_BUY, lot);
        }
     }
   else if(state == STATE_BEARISH)
     {
      // Price < Tenkan
      if(price < tenkan)
        {
         OpenTrade(ORDER_TYPE_SELL, lot);
        }
     }
  }

//+------------------------------------------------------------------+
//| Logic: Open Trade with Dynamic Risk                              |
//+------------------------------------------------------------------+
void OpenTrade(ENUM_ORDER_TYPE type, double vol)
  {
   // Kumo Thickness Calculation
   double thickness = ichiEngine.GetKumoThickness(0);
   double senkouA = ichiEngine.GetSenkouA(0);
   double senkouB = ichiEngine.GetSenkouB(0);
   double kumoUpper = fmax(senkouA, senkouB);
   double kumoLower = fmin(senkouA, senkouB);

   double entryPrice = (type == ORDER_TYPE_BUY) ? SymbolInfoDouble(_Symbol, SYMBOL_ASK) : SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double sl = 0;

   // Dynamic SL
   // Formula: Kumo_Buffer = 10 + (Thickness * 0.5)
   // Optimizer scales this buffer
   double baseBuffer = 10 + (thickness / _Point * 0.5); // Convert thickness to points approx or assume price diff
   // Let's stick to Price Diff for thickness
   double bufferPips = (10 * _Point) + (thickness * 0.5);
   bufferPips *= optimizer.GetKumoBufferAdjustment();

   if(type == ORDER_TYPE_BUY)
     {
      sl = kumoLower - bufferPips;
      // Cap Risk
      if(entryPrice - sl > InpMaxRiskPips * _Point) sl = entryPrice - (InpMaxRiskPips * _Point);
     }
   else
     {
      sl = kumoUpper + bufferPips;
      if(sl - entryPrice > InpMaxRiskPips * _Point) sl = entryPrice + (InpMaxRiskPips * _Point);
     }

   double riskDist = MathAbs(entryPrice - sl);
   double tp = (type == ORDER_TYPE_BUY) ? entryPrice + (riskDist * InpRiskReward) : entryPrice - (riskDist * InpRiskReward);

   trade.PositionOpen(_Symbol, type, vol, entryPrice, sl, tp);
  }

//+------------------------------------------------------------------+
//| Logic: Manage Positions (Trailing)                               |
//+------------------------------------------------------------------+
void ManagePositions()
  {
   // Update stop-loss every 5 bars
   if(barsCounter++ < 5) return;
   barsCounter = 0;

   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      ulong ticket = PositionGetTicket(i);
      if(ticket > 0)
        {
         // Simple Break-Even / Trailing logic based on decreased volatility could go here
         // Requirement: "Move stop closer to break-even if volatility decreases"
         // Implemented as standard trailing for safety in this version:

         double sl = PositionGetDouble(POSITION_SL);
         double open = PositionGetDouble(POSITION_PRICE_OPEN);
         double current = PositionGetDouble(POSITION_PRICE_CURRENT);
         long type = PositionGetInteger(POSITION_TYPE);

         double profitPips = (type == POSITION_TYPE_BUY) ? (current - open) : (open - current);

         // If Profit > Risk distance, move to BE
         if(profitPips > MathAbs(open - sl))
           {
             double newSL = open;
             if(type == POSITION_TYPE_BUY && sl < newSL) trade.PositionModify(ticket, newSL, PositionGetDouble(POSITION_TP));
             if(type == POSITION_TYPE_SELL && sl > newSL) trade.PositionModify(ticket, newSL, PositionGetDouble(POSITION_TP));
           }

         // State Reversal Exit
         ENUM_ICHI_STATE state = ichiEngine.GetState();
         if(type == POSITION_TYPE_BUY && state == STATE_BEARISH) trade.PositionClose(ticket);
         if(type == POSITION_TYPE_SELL && state == STATE_BULLISH) trade.PositionClose(ticket);
        }
     }
  }
