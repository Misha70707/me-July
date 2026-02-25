//+------------------------------------------------------------------+
//|                                             Gold_Ichimoku_VR.mq5 |
//|                                  Copyright 2024, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.01"

#include <Trade\Trade.mqh>
#include <AdaptiveIchimoku.mqh>
#include <RecursiveOptimizer.mqh>
#include <ZenithProtocol.mqh> // Integrated Protocol

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
bool                 g_protocolSafe = false;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
   // 1. Zenith Protocol Validation
   if(!CZenithSentinel::ValidateEnvironment())
     {
      Print("Zenith Protocol: Environment Validation Failed. Expert Stopped.");
      return INIT_FAILED;
     }
   g_protocolSafe = true;

   // 2. Component Initialization
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
   g_protocolSafe = false;
  }

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
   // Protocol Gate
   if(!g_protocolSafe) return;

   ulong startT = GetMicrosecondCount();

   // 1. Check New Bar
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

   ulong endT = GetMicrosecondCount();
   CZenithSentinel::LogPerformance("OnTick", endT - startT);
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
   if(optimizer.ShouldPauseTrading()) return;
   if(PositionsTotal() > 0) return;

   ENUM_ICHI_STATE state = ichiEngine.GetState();
   int barsInState = ichiEngine.GetBarsInState();

   if(barsInState < 1) return;

   double price = iClose(_Symbol, PERIOD_CURRENT, 0);
   double tenkan = ichiEngine.GetTenkan(0);

   double lot = InpLotSize;
   if(optimizer.ShouldReduceRisk()) lot = InpLotSize * 0.5;

   // Zenith Protocol: Bounds Check on Lot
   if(lot <= 0) lot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);

   if(state == STATE_BULLISH)
     {
      if(price > tenkan) OpenTrade(ORDER_TYPE_BUY, lot);
     }
   else if(state == STATE_BEARISH)
     {
      if(price < tenkan) OpenTrade(ORDER_TYPE_SELL, lot);
     }
  }

//+------------------------------------------------------------------+
//| Logic: Open Trade with Dynamic Risk                              |
//+------------------------------------------------------------------+
void OpenTrade(ENUM_ORDER_TYPE type, double vol)
  {
   double thickness = ichiEngine.GetKumoThickness(0);
   double senkouA = ichiEngine.GetSenkouA(0);
   double senkouB = ichiEngine.GetSenkouB(0);
   double kumoUpper = fmax(senkouA, senkouB);
   double kumoLower = fmin(senkouA, senkouB);

   double entryPrice = (type == ORDER_TYPE_BUY) ? SymbolInfoDouble(_Symbol, SYMBOL_ASK) : SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double sl = 0;

   double bufferPips = (10 * _Point) + (thickness * 0.5);
   bufferPips *= optimizer.GetKumoBufferAdjustment();

   if(type == ORDER_TYPE_BUY)
     {
      sl = kumoLower - bufferPips;
      if(entryPrice - sl > InpMaxRiskPips * _Point) sl = entryPrice - (InpMaxRiskPips * _Point);
     }
   else
     {
      sl = kumoUpper + bufferPips;
      if(sl - entryPrice > InpMaxRiskPips * _Point) sl = entryPrice + (InpMaxRiskPips * _Point);
     }

   double riskDist = MathAbs(entryPrice - sl);
   // Zenith Protocol: Safety Check for Zero Risk Distance
   if(riskDist < _Point) riskDist = 10 * _Point;

   double tp = (type == ORDER_TYPE_BUY) ? entryPrice + (riskDist * InpRiskReward) : entryPrice - (riskDist * InpRiskReward);

   trade.PositionOpen(_Symbol, type, vol, entryPrice, sl, tp);
  }

//+------------------------------------------------------------------+
//| Logic: Manage Positions (Trailing)                               |
//+------------------------------------------------------------------+
void ManagePositions()
  {
   if(barsCounter++ < 5) return;
   barsCounter = 0;

   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      ulong ticket = PositionGetTicket(i);
      if(ticket > 0)
        {
         double sl = PositionGetDouble(POSITION_SL);
         double open = PositionGetDouble(POSITION_PRICE_OPEN);
         double current = PositionGetDouble(POSITION_PRICE_CURRENT);
         long type = PositionGetInteger(POSITION_TYPE);

         double profitPips = (type == POSITION_TYPE_BUY) ? (current - open) : (open - current);

         if(profitPips > MathAbs(open - sl))
           {
             double newSL = open;
             if(type == POSITION_TYPE_BUY && sl < newSL) trade.PositionModify(ticket, newSL, PositionGetDouble(POSITION_TP));
             if(type == POSITION_TYPE_SELL && sl > newSL) trade.PositionModify(ticket, newSL, PositionGetDouble(POSITION_TP));
           }

         ENUM_ICHI_STATE state = ichiEngine.GetState();
         if(type == POSITION_TYPE_BUY && state == STATE_BEARISH) trade.PositionClose(ticket);
         if(type == POSITION_TYPE_SELL && state == STATE_BULLISH) trade.PositionClose(ticket);
        }
     }
  }
