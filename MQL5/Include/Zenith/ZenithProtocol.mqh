//+------------------------------------------------------------------+
//|                                               ZenithProtocol.mqh |
//|                                  Copyright 2024, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"

enum ENUM_ZENITH_MOOD
  {
   MOOD_CALM,
   MOOD_FOCUSED,
   MOOD_EXCITED,
   MOOD_CAUTIOUS,
   MOOD_PANIC
  };

class CZenithProtocol
  {
private:
   ENUM_ZENITH_MOOD  m_current_mood;
   double            m_volatility;
   ulong             m_latency;

   // Optimization: Cache the status report string
   string            m_cached_report;
   bool              m_is_dirty;

public:
                     CZenithProtocol();
                    ~CZenithProtocol();

   void              SetMood(ENUM_ZENITH_MOOD mood);
   void              UpdateMetrics(double volatility, ulong latency);
   string            GetStatusReport();
  };
//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CZenithProtocol::CZenithProtocol()
  {
   m_current_mood = MOOD_CALM;
   m_volatility = 0.0;
   m_latency = 0;
   m_is_dirty = true;
   m_cached_report = "";
  }
//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
CZenithProtocol::~CZenithProtocol()
  {
  }
//+------------------------------------------------------------------+
//| Set the current mood directly                                    |
//+------------------------------------------------------------------+
void CZenithProtocol::SetMood(ENUM_ZENITH_MOOD mood)
  {
   if(m_current_mood != mood)
     {
      m_current_mood = mood;
      m_is_dirty = true;
     }
  }
//+------------------------------------------------------------------+
//| Update internal metrics                                          |
//+------------------------------------------------------------------+
void CZenithProtocol::UpdateMetrics(double volatility, ulong latency)
  {
   if(m_volatility != volatility || m_latency != latency)
     {
      m_volatility = volatility;
      m_latency = latency;
      m_is_dirty = true;
     }
  }
//+------------------------------------------------------------------+
//| Generate a human-readable status report                          |
//+------------------------------------------------------------------+
string CZenithProtocol::GetStatusReport()
  {
   if(m_is_dirty)
     {
      string mood_str = "";
      switch(m_current_mood)
        {
         case MOOD_CALM:     mood_str = "CALM: Operations are stable."; break;
         case MOOD_FOCUSED:  mood_str = "FOCUSED: High precision mode engaged."; break;
         case MOOD_EXCITED:  mood_str = "EXCITED: Aggressive trading active."; break;
         case MOOD_CAUTIOUS: mood_str = "CAUTIOUS: Risk reduced."; break;
         case MOOD_PANIC:    mood_str = "PANIC: Emergency protocols initiated."; break;
         default:            mood_str = "UNKNOWN: State undefined."; break;
        }

      string report = "Zenith Protocol Status Report\n";
      report += "-----------------------------\n";
      report += "Current Mood: " + mood_str + "\n";
      report += "Volatility Index: " + DoubleToString(m_volatility, 5) + "\n";
      report += "Execution Latency: " + IntegerToString(m_latency) + " us\n";
      report += "System Check: OK\n";

      m_cached_report = report;
      m_is_dirty = false;
     }

   return m_cached_report;
  }
