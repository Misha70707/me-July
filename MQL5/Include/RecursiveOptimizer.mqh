//+------------------------------------------------------------------+
//|                                           RecursiveOptimizer.mqh |
//|                                  Copyright 2024, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"

struct OptParams
  {
   double kumoMult;
   double periodMult;
   datetime timestamp;
  };

//+------------------------------------------------------------------+
//| Struct: OptimizationStats                                        |
//| Usage: Holds session performance metrics                         |
//+------------------------------------------------------------------+
struct OptimizationStats
  {
   int               totalTrades;
   int               wins;
   int               losses;
   int               consecutiveLosses;
   double            currentDrawdown;
   double            maxDrawdown;
   double            accumulatedProfit;
   double            winRate;
   datetime          lastTradeTime;

   void Init()
     {
      totalTrades = 0;
      wins = 0;
      losses = 0;
      consecutiveLosses = 0;
      currentDrawdown = 0.0;
      maxDrawdown = 0.0;
      accumulatedProfit = 0.0;
      winRate = 0.0;
      lastTradeTime = 0;
     }
  };

//+------------------------------------------------------------------+
//| Class: CRecursiveOptimizer                                       |
//| Purpose: Adaptive parameter tuning based on performance          |
//+------------------------------------------------------------------+
class CRecursiveOptimizer
  {
private:
   OptimizationStats m_stats;
   double            m_initialBalance;

   // Adaptation Factors (Multipliers)
   double            m_kumoBufferMultiplier;
   double            m_periodMultiplier;

   // History for Rollback
   OptParams         m_history[5];
   int               m_historyIndex;

   // Bounds
   const double      MIN_KUMO_MULT;
   const double      MAX_KUMO_MULT;

public:
                     CRecursiveOptimizer();
                    ~CRecursiveOptimizer();

   void              Init(double initialBalance);
   void              OnTradeClosed(double profit, double balance);

   // Getters for Adaptive Logic
   double            GetKumoBufferAdjustment();
   double            GetPeriodAdjustment();

   // Status Checks
   bool              ShouldPauseTrading();
   bool              ShouldReduceRisk();

private:
   void              UpdateMetrics(double profit, double balance);
   void              RecalculateFactors();
   void              LogChange(string reason, double oldVal, double newVal);
   void              PushHistory();
  };

//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CRecursiveOptimizer::CRecursiveOptimizer() :
   MIN_KUMO_MULT(0.8),
   MAX_KUMO_MULT(1.5),
   m_historyIndex(0)
  {
   m_kumoBufferMultiplier = 1.0;
   m_periodMultiplier = 1.0;
   ZeroMemory(m_history);
  }

//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
CRecursiveOptimizer::~CRecursiveOptimizer()
  {
  }

//+------------------------------------------------------------------+
//| Initialization                                                   |
//+------------------------------------------------------------------+
void CRecursiveOptimizer::Init(double initialBalance)
  {
   m_stats.Init();
   m_initialBalance = initialBalance;
   if(m_initialBalance <= 0) m_initialBalance = AccountInfoDouble(ACCOUNT_BALANCE);

   // Store initial state
   PushHistory();
  }

//+------------------------------------------------------------------+
//| Store current params in circular buffer                          |
//+------------------------------------------------------------------+
void CRecursiveOptimizer::PushHistory()
  {
   m_history[m_historyIndex].kumoMult = m_kumoBufferMultiplier;
   m_history[m_historyIndex].periodMult = m_periodMultiplier;
   m_history[m_historyIndex].timestamp = TimeCurrent();

   m_historyIndex++;
   if(m_historyIndex >= 5) m_historyIndex = 0;
  }

//+------------------------------------------------------------------+
//| Log Parameter Change                                             |
//+------------------------------------------------------------------+
void CRecursiveOptimizer::LogChange(string reason, double oldVal, double newVal)
  {
   PrintFormat("OPTIMIZER: %s changed from %.2f to %.2f. Reason: %s",
               reason, oldVal, newVal, reason);
  }

//+------------------------------------------------------------------+
//| Update metrics after a trade closes                              |
//+------------------------------------------------------------------+
void CRecursiveOptimizer::OnTradeClosed(double profit, double balance)
  {
   UpdateMetrics(profit, balance);
   RecalculateFactors();
  }

//+------------------------------------------------------------------+
//| Internal metric update                                           |
//+------------------------------------------------------------------+
void CRecursiveOptimizer::UpdateMetrics(double profit, double balance)
  {
   m_stats.totalTrades++;
   m_stats.accumulatedProfit += profit;
   m_stats.lastTradeTime = TimeCurrent();

   if(profit > 0)
     {
      m_stats.wins++;
      m_stats.consecutiveLosses = 0;
     }
   else
     {
      m_stats.losses++;
      m_stats.consecutiveLosses++;
     }

   // Calc Win Rate
   if(m_stats.totalTrades > 0)
      m_stats.winRate = (double)m_stats.wins / m_stats.totalTrades;

   // Calc Drawdown
   double peak = fmax(m_initialBalance, balance - profit);
   if(balance < m_initialBalance)
      m_stats.currentDrawdown = (m_initialBalance - balance) / m_initialBalance * 100.0;
   else
      m_stats.currentDrawdown = 0.0;

   if(m_stats.currentDrawdown > m_stats.maxDrawdown)
      m_stats.maxDrawdown = m_stats.currentDrawdown;
  }

//+------------------------------------------------------------------+
//| Recalculate Adaptation Factors                                   |
//+------------------------------------------------------------------+
void CRecursiveOptimizer::RecalculateFactors()
  {
   double oldKumo = m_kumoBufferMultiplier;
   bool changed = false;

   // 1. Win Rate Adaptation
   // IF Win_Rate < 40% for last 20 trades
   if(m_stats.totalTrades >= 20 && m_stats.winRate < 0.40)
     {
      m_kumoBufferMultiplier += 0.05; // Tighten entry/exit criteria
      changed = true;
     }
   else if(m_stats.totalTrades >= 20 && m_stats.winRate > 0.60)
     {
      m_kumoBufferMultiplier -= 0.02; // Loosen slightly if winning well
      changed = true;
     }

   // Clamp
   if(m_kumoBufferMultiplier > MAX_KUMO_MULT) m_kumoBufferMultiplier = MAX_KUMO_MULT;
   if(m_kumoBufferMultiplier < MIN_KUMO_MULT) m_kumoBufferMultiplier = MIN_KUMO_MULT;

   if(changed)
     {
      LogChange("KumoBufferMultiplier", oldKumo, m_kumoBufferMultiplier);
      PushHistory();
     }

   // 2. Duration Adaptation (Simplified placeholder)
   // Not directly implemented as multiplier here.
  }

//+------------------------------------------------------------------+
//| Getters                                                          |
//+------------------------------------------------------------------+
double CRecursiveOptimizer::GetKumoBufferAdjustment()
  {
   return m_kumoBufferMultiplier;
  }

double CRecursiveOptimizer::GetPeriodAdjustment()
  {
   // If volatility is causing whipsaws (low winrate), we might want to lengthen periods slightly
   if(m_stats.consecutiveLosses > 3) return 1.1;
   return 1.0;
  }

bool CRecursiveOptimizer::ShouldPauseTrading()
  {
   // IF Consecutive_Losses > 6 THEN Pause
   return (m_stats.consecutiveLosses > 6);
  }

bool CRecursiveOptimizer::ShouldReduceRisk()
  {
   // IF Drawdown > 15%
   return (m_stats.currentDrawdown > 15.0);
  }
