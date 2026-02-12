//+------------------------------------------------------------------+
//|                                           Zenith_Demo_EA.mq5     |
//|                        Copyright 2025, MetaQuotes Ltd.           |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"

#include <Zenith/ZenithProtocol.mqh>

// Global object
CZenithProtocol Zenith;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
   // Perform initial self-check
   Print("Initializing Zenith Protocol...");
   if(!Zenith.SelfDiagnose())
     {
      Print("Zenith Protocol Self-Diagnostic Failed! Check logs.");
      return(INIT_FAILED);
     }

   Print("Zenith Protocol Initialized Successfully. Mood: ", EnumToString(Zenith.GetMood()));
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   Comment(""); // Clear chart
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
   // 1. Let Zenith assess the environment first
   Zenith.AssessEnvironment();

   // 2. React to Zenith's findings
   ENUM_ZENITH_MOOD mood = Zenith.GetMood();

   switch(mood)
     {
      case MOOD_LAGGY:
         // If lagging, skip heavy calculations or reduce frequency
         Print("Zenith reports lag. Skipping heavy logic.");
         break;

      case MOOD_VOLATILE:
         // If volatile, maybe tighten stops or reduce position size
         // (Placeholder logic)
         break;

      case MOOD_ANXIOUS:
         // Something is wrong (disconnected?), maybe close positions?
         break;

      case MOOD_CALM:
         // Business as usual
         break;
     }

   // 3. Display the "Little Helper's" thoughts on the chart
   Comment(Zenith.GetStatusReport());
  }
