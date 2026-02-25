//+------------------------------------------------------------------+
//|                                               ZenithProtocol.mqh |
//|                                  Copyright 2024, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"

//+------------------------------------------------------------------+
//| ZENITH PROTOCOL: High-Reliability Standards                      |
//+------------------------------------------------------------------+
#define ZENITH_VERSION "1.0.0"

// Safety Macros
#define ZENITH_ASSERT(condition, message)    if(!(condition)) {       PrintFormat("ZENITH CRITICAL [Line %d]: %s", __LINE__, message);       return;    }

#define ZENITH_ASSERT_RET(condition, message, retval)    if(!(condition)) {       PrintFormat("ZENITH CRITICAL [Line %d]: %s", __LINE__, message);       return retval;    }

#define ZENITH_CHECK_POINTER(ptr)    if(CheckPointer(ptr) == POINTER_INVALID) {       PrintFormat("ZENITH NULL POINTER [Line %d]", __LINE__);       return;    }

//+------------------------------------------------------------------+
//| Class: CZenithSentinel                                           |
//| Purpose: Runtime Environment Integrity Checker                   |
//+------------------------------------------------------------------+
class CZenithSentinel
  {
public:
   static bool ValidateEnvironment()
     {
      Print("--------------------------------------------------");
      PrintFormat("ZENITH PROTOCOL v%s: INITIATING SEQUENTIAL CHECK", ZENITH_VERSION);

      // 1. Memory Integrity
      int memLimit = MQLInfoInteger(MQL_MEMORY_LIMIT);
      int memUsed = MQLInfoInteger(MQL_MEMORY_USED);
      PrintFormat(" >> Memory: %d MB Used / %d MB Limit", memUsed, memLimit);

      if(memLimit > 0 && (double)memUsed / memLimit > 0.8)
        {
         Print(" >> WARNING: Memory usage critical (>80%)");
         return false;
        }

      // 2. Account Integrity
      if(!AccountInfoInteger(ACCOUNT_TRADE_ALLOWED))
        {
         Print(" >> WARNING: Trading not allowed for this account");
         // Not blocking, maybe just analysis mode, but log it.
        }

      if(!TerminalInfoInteger(TERMINAL_TRADE_ALLOWED))
        {
         Print(" >> CRITICAL: AutoTrading disabled in Terminal");
         return false;
        }

      Print("ZENITH PROTOCOL: INTEGRITY CONFIRMED");
      Print("--------------------------------------------------");
      return true;
     }

   static void LogPerformance(string context, ulong durationMicro)
     {
      // Log only outliers > 1ms (1000us) to keep logs clean
      if(durationMicro > 1000)
        {
         PrintFormat("ZENITH PERF [%s]: %d us (Latency Spike Detected)", context, durationMicro);
        }
     }
  };
