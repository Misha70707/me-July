//+------------------------------------------------------------------+
//|                                           ZenithProtocol.mqh     |
//|                        Copyright 2025, MetaQuotes Ltd.           |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property strict

// Zenith Mood States
enum ENUM_ZENITH_MOOD
  {
   MOOD_CALM,     // Low volatility, stable latency
   MOOD_VOLATILE, // High volatility (ATR spike)
   MOOD_LAGGY,    // High execution latency detected
   MOOD_ANXIOUS   // Anomalies detected (e.g., bad data)
  };

//+------------------------------------------------------------------+
//| Class CZenithProtocol                                            |
//| "A little helper environment that makes sense to me (Jules)"     |
//+------------------------------------------------------------------+
class CZenithProtocol
  {
private:
   // Internal Metrics
   ulong    m_last_tick_time;
   double   m_volatility_avg;
   double   m_latency_avg;
   int      m_tick_count;

   // State
   ENUM_ZENITH_MOOD m_current_mood;
   string           m_status_message;

   // Caching
   string           m_cached_report;
   bool             m_is_dirty;

public:
                     CZenithProtocol();
                    ~CZenithProtocol();

   // Core Functions
   void              AssessEnvironment();
   ENUM_ZENITH_MOOD  GetMood() const { return m_current_mood; }
   string            GetStatusReport();

   // Diagnostics
   bool              SelfDiagnose();

private:
   double            CalculateVolatility();
   void              UpdateLatency(ulong execution_time);
  };
//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CZenithProtocol::CZenithProtocol() : m_last_tick_time(0),
                                     m_volatility_avg(0.0),
                                     m_latency_avg(0.0),
                                     m_tick_count(0),
                                     m_current_mood(MOOD_CALM),
                                     m_status_message("Initializing Zenith Protocol..."),
                                     m_cached_report(""),
                                     m_is_dirty(true)
  {
  }
//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
CZenithProtocol::~CZenithProtocol()
  {
  }
//+------------------------------------------------------------------+
//| Assess the current market and system environment                 |
//+------------------------------------------------------------------+
void CZenithProtocol::AssessEnvironment()
  {
   ulong start_time = GetMicrosecondCount();

   // 1. Calculate Volatility (Simple High-Low range for demo)
   double current_volatility = CalculateVolatility();

   // update average volatility (simple moving average for demo)
   if(m_tick_count == 0) m_volatility_avg = current_volatility;
   else m_volatility_avg = (m_volatility_avg * 0.9) + (current_volatility * 0.1);

   // 2. Measure Execution Latency
   ulong end_time = GetMicrosecondCount();
   ulong latency = end_time - start_time;
   UpdateLatency(latency);

   // 3. Determine Mood based on metrics
   if(m_latency_avg > 100000) // >100ms (100,000us) average latency is bad
     {
      m_current_mood = MOOD_LAGGY;
      m_status_message = "System is lagging. Reducing update frequency recommended.";
     }
   else if(current_volatility > m_volatility_avg * 1.5) // Spiking volatility
     {
      m_current_mood = MOOD_VOLATILE;
      m_status_message = "Market is heating up! Adjusting risk parameters.";
     }
   else if(current_volatility < m_volatility_avg * 0.5) // Very low volatility
     {
      m_current_mood = MOOD_CALM;
      m_status_message = "Market is quiet. Monitoring for breakout.";
     }
   else
     {
      m_current_mood = MOOD_CALM;
      m_status_message = "All systems nominal.";
     }

   m_tick_count++;
   m_last_tick_time = GetMicrosecondCount();
   m_is_dirty = true;
  }
//+------------------------------------------------------------------+
//| Calculate immediate volatility (High - Low of current bar)       |
//+------------------------------------------------------------------+
double CZenithProtocol::CalculateVolatility()
  {
   MqlRates rates[];
   if(CopyRates(_Symbol, PERIOD_CURRENT, 0, 1, rates) > 0)
     {
      return rates[0].high - rates[0].low;
     }
   return 0.0;
  }
//+------------------------------------------------------------------+
//| Update running average of execution latency                      |
//+------------------------------------------------------------------+
void CZenithProtocol::UpdateLatency(ulong execution_time)
  {
   if(m_tick_count == 0) m_latency_avg = (double)execution_time;
   else m_latency_avg = (m_latency_avg * 0.95) + ((double)execution_time * 0.05);
  }
//+------------------------------------------------------------------+
//| Self-Diagnostic Health Check                                     |
//+------------------------------------------------------------------+
bool CZenithProtocol::SelfDiagnose()
  {
   // Check 1: Is symbol info available?
   if(!SymbolSelect(_Symbol, true))
     {
      m_current_mood = MOOD_ANXIOUS;
      m_status_message = "CRITICAL: Symbol selection failed!";
      m_is_dirty = true;
      return false;
     }

   // Check 2: Are we connected?
   if(!TerminalInfoInteger(TERMINAL_CONNECTED))
     {
      m_current_mood = MOOD_ANXIOUS;
      m_status_message = "WARNING: Terminal disconnected!";
      m_is_dirty = true;
      return false;
     }

   return true;
  }
//+------------------------------------------------------------------+
//| Generate a human-readable status report                          |
//+------------------------------------------------------------------+
string CZenithProtocol::GetStatusReport()
  {
   if(!m_is_dirty)
      return m_cached_report;

   string mood_str = "";
   switch(m_current_mood)
     {
      case MOOD_CALM:     mood_str = "CALM 😌"; break;
      case MOOD_VOLATILE: mood_str = "VOLATILE ⚡"; break;
      case MOOD_LAGGY:    mood_str = "LAGGY 🐢"; break;
      case MOOD_ANXIOUS:  mood_str = "ANXIOUS ⚠️"; break;
     }

   string report = "╔════════════ ZENITH PROTOCOL ════════════╗\n";
   report += StringFormat("║ Mood: %-33s ║\n", mood_str);
   report += StringFormat("║ Latency (avg): %-24.2f us ║\n", m_latency_avg); // us for microseconds
   report += StringFormat("║ Volatility: %-27.5f ║\n", m_volatility_avg);
   report += StringFormat("║ Status: %-31s ║\n", StringSubstr(m_status_message, 0, 31)); // Truncate for safety
   report += "╚═════════════════════════════════════════╝";

   m_cached_report = report;
   m_is_dirty = false;

   return m_cached_report;
  }
