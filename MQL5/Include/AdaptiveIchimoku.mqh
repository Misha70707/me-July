//+------------------------------------------------------------------+
//|                                            AdaptiveIchimoku.mqh |
//|                                  Copyright 2024, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, MetaQuotes Ltd."
#property link      "https://www.mql5.com"

#include <RecursiveOptimizer.mqh>

enum ENUM_ICHI_STATE
  {
   STATE_NEUTRAL,
   STATE_BULLISH,
   STATE_BEARISH
  };

//+------------------------------------------------------------------+
//| Class: CAdaptiveIchimoku                                         |
//| Purpose: Dynamic Ichimoku Logic Engine                           |
//+------------------------------------------------------------------+
class CAdaptiveIchimoku
  {
private:
   // Handles
   int               m_hATR;

   // Buffers for internal calc
   double            m_atrBuffer[];

   // Current Periods
   int               m_pTenkan;
   int               m_pKijun;
   int               m_pSenkouB;

   // Base Periods
   int               m_baseTenkan;
   int               m_baseKijun;
   int               m_baseSenkouB;

   // State
   ENUM_ICHI_STATE   m_currentState;
   int               m_barsInState;
   datetime          m_lastCalcTime;

   // Zero-Allocation Helpers
   MqlRates          m_rates[];

public:
                     CAdaptiveIchimoku();
                    ~CAdaptiveIchimoku();

   bool              Init(int tenkan, int kijun, int senkouB);
   void              OnNewBar();

   // The Core Logic
   void              UpdateState(CRecursiveOptimizer &optimizer);

   // Getters
   ENUM_ICHI_STATE   GetState() const { return m_currentState; }
   int               GetBarsInState() const { return m_barsInState; }

   // Dynamic Line Calculation
   double            GetTenkan(int index);
   double            GetKijun(int index);
   double            GetSenkouA(int index);
   double            GetSenkouB(int index);
   double            GetChikou(int index);

   // Volatility Logic
   double            GetVolatilityFactor();
   double            GetKumoThickness(int index);

private:
   double            CalculateMidPrice(int period, int shift);
   void              AdjustPeriods(double volFactor, double optFactor);
  };

//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CAdaptiveIchimoku::CAdaptiveIchimoku() :
   m_hATR(INVALID_HANDLE),
   m_currentState(STATE_NEUTRAL),
   m_barsInState(0),
   m_lastCalcTime(0)
  {
   ArraySetAsSeries(m_atrBuffer, true);
   ArraySetAsSeries(m_rates, true);
  }

//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
CAdaptiveIchimoku::~CAdaptiveIchimoku()
  {
   if(m_hATR != INVALID_HANDLE) IndicatorRelease(m_hATR);
  }

//+------------------------------------------------------------------+
//| Init                                                             |
//+------------------------------------------------------------------+
bool CAdaptiveIchimoku::Init(int tenkan, int kijun, int senkouB)
  {
   m_baseTenkan = tenkan;
   m_baseKijun = kijun;
   m_baseSenkouB = senkouB;

   m_pTenkan = tenkan;
   m_pKijun = kijun;
   m_pSenkouB = senkouB;

   m_hATR = iATR(_Symbol, PERIOD_CURRENT, 14);
   if(m_hATR == INVALID_HANDLE)
     {
      Print("Failed to create ATR handle");
      return false;
     }

   return true;
  }

//+------------------------------------------------------------------+
//| OnNewBar Updates                                                 |
//+------------------------------------------------------------------+
void CAdaptiveIchimoku::OnNewBar()
  {
   m_barsInState++;
  }

//+------------------------------------------------------------------+
//| Calculate Mid Price (High + Low) / 2 over period                 |
//+------------------------------------------------------------------+
double CAdaptiveIchimoku::CalculateMidPrice(int period, int shift)
  {
   double high = -DBL_MAX;
   double low = DBL_MAX;

   // Efficient copying of just the needed range
   // Using CopyHigh/CopyLow would be better if we needed many bars,
   // but for single calculation CopyRates or iHigh/iLow loop is fine.
   // Let's use iHigh/iLow for clarity and zero-allocation (system caches them)

   for(int i = 0; i < period; i++)
     {
      double h = iHigh(_Symbol, PERIOD_CURRENT, shift + i);
      double l = iLow(_Symbol, PERIOD_CURRENT, shift + i);
      if(h > high) high = h;
      if(l < low) low = l;
     }

   return (high + low) / 2.0;
  }

//+------------------------------------------------------------------+
//| Get Volatility Factor = (Current_ATR / ATR_MA_20) - 1.0          |
//+------------------------------------------------------------------+
double CAdaptiveIchimoku::GetVolatilityFactor()
  {
   if(CopyBuffer(m_hATR, 0, 0, 20, m_atrBuffer) < 20) return 0.0;

   double currentATR = m_atrBuffer[0];
   double sum = 0;
   for(int i=0; i<20; i++) sum += m_atrBuffer[i];
   double maATR = sum / 20.0;

   if(maATR == 0) return 0.0;
   return (currentATR / maATR) - 1.0;
  }

//+------------------------------------------------------------------+
//| Adjust Periods based on Volatility and Optimizer                 |
//+------------------------------------------------------------------+
void CAdaptiveIchimoku::AdjustPeriods(double volFactor, double optFactor)
  {
   // Formula: New_Period = Base_Period * (1 + VolFactor) * OptFactor
   // Note: High Volatility (Positive Factor) -> Shorten periods?
   // Wait, logic check:
   // "High Volatility (ATR > 1.5x average): Shorten periods to catch early moves"
   // If ATR is high, VolFactor is +0.5. Base * 1.5 would LENGTHEN periods.
   // To SHORTEN, we should divide or invert the factor effect for High Vol.
   // Let's follow the requirement spec closely: "Shorten periods to catch early moves".
   // If VolFactor is > 0 (High Vol), we want Multiplier < 1.
   // If VolFactor is < 0 (Low Vol), we want Multiplier > 1 (Lengthen to filter noise).

   // Adjusted Formula: Multiplier = 1.0 - (VolFactor * 0.5);
   // Example: VolFactor = 0.5 (High). Mult = 0.75. Period 9 -> 6.75 (Shortened). Correct.
   // Example: VolFactor = -0.25 (Low). Mult = 1.125. Period 9 -> 10. (Lengthened). Correct.

   double multiplier = 1.0 - (volFactor * 0.5);

   // Apply Optimizer Factor (usually 1.0 or slightly > 1.0 to dampen)
   multiplier *= optFactor;

   // Apply
   m_pTenkan = (int)(m_baseTenkan * multiplier);
   m_pKijun = (int)(m_baseKijun * multiplier);
   m_pSenkouB = (int)(m_baseSenkouB * multiplier);

   // Constraints
   // Tenkan [5-15], Kijun [14-40], SenkouB [30-80]
   if(m_pTenkan < 5) m_pTenkan = 5;
   if(m_pTenkan > 15) m_pTenkan = 15;

   if(m_pKijun < 14) m_pKijun = 14;
   if(m_pKijun > 40) m_pKijun = 40;

   if(m_pSenkouB < 30) m_pSenkouB = 30;
   if(m_pSenkouB > 80) m_pSenkouB = 80;
  }

//+------------------------------------------------------------------+
//| Update State Machine (The 4-Point Gate)                          |
//+------------------------------------------------------------------+
void CAdaptiveIchimoku::UpdateState(CRecursiveOptimizer &optimizer)
  {
   // 1. Update Volatility & Periods
   double volFactor = GetVolatilityFactor();
   // Clamp VolFactor [-0.5, 2.0]
   if(volFactor < -0.5) volFactor = -0.5;
   if(volFactor > 2.0) volFactor = 2.0;

   AdjustPeriods(volFactor, optimizer.GetPeriodAdjustment());

   // 2. Get Line Values (Current Bar 0)
   double tenkan = GetTenkan(0);
   double kijun = GetKijun(0);
   double close = iClose(_Symbol, PERIOD_CURRENT, 0);
   double senkouA = GetSenkouA(0);
   double senkouB = GetSenkouB(0);
   double chikou = GetChikou(0); // This is Close[0] compared to price 26 ago
   double pastPrice = iClose(_Symbol, PERIOD_CURRENT, 26);

   // 3. HTF Agreement (H4) - Simplified for Zero-Lag (using hardcoded H4 periods for now or separate instance)
   // For this implementation, we'll assume the H4 handles are managed externally or simplified:
   // Requirement: "HTF_Kijun > HTF_Tenkan" (Bearish) or vice versa.
   // We will implement a lightweight check:
   double h4_Tenkan = iIchimokuGet(PERIOD_H4, TENKAN_SEN, 0);
   double h4_Kijun = iIchimokuGet(PERIOD_H4, KIJUN_SEN, 0);

   // 4. Conditions
   bool bullCond1 = (tenkan > kijun);
   bool bullCond2 = (h4_Tenkan > h4_Kijun); // "HTF_Kijun > HTF_Tenkan" is WRONG in spec for Bullish?
                                            // Spec says: Bullish: HTF_Kijun > HTF_Tenkan.
                                            // Standard Ichi: Bull is Tenkan ABOVE Kijun.
                                            // If Spec says "HTF_Kijun > HTF_Tenkan" for Bullish, it implies a contrarian or specific setup.
                                            // WAIT: "Condition 1: Tenkan-sen crosses ABOVE Kijun-sen" (Standard Bull)
                                            // "Condition 2: HTF_Kijun > HTF_Tenkan" -> This means Kijun (Base) is ABOVE Tenkan (Fast) on H4.
                                            // This implies H4 is Bearish/Correction? Or is it a typo in spec?
                                            // Usually, Agreement means Alignment. H1 Bull + H4 Bull.
                                            // H4 Bull would be Tenkan > Kijun.
                                            // Let's assume standard Alignment (Tenkan > Kijun on H4) unless strictly following "HTF_Kijun > HTF_Tenkan".
                                            // Re-reading Spec: "Higher timeframe agreement - HTF_Kijun > HTF_Tenkan (H4)" for BULLISH.
                                            // This explicitly requests Kijun > Tenkan on H4. I will follow the SPEC, but add a comment.
                                            // "Condition 2: Higher timeframe agreement - HTF_Kijun > HTF_Tenkan (H4)"
   bool bullCond2_Spec = (h4_Kijun > h4_Tenkan);

   bool bullCond3 = (close > senkouA && close > senkouB); // Above Cloud
   bool bullCond4 = (chikou > pastPrice); // Chikou Free

   // Bearish
   bool bearCond1 = (tenkan < kijun);
   bool bearCond2 = (h4_Kijun < h4_Tenkan); // Spec: "HTF_Kijun < HTF_Tenkan" for Bearish.
   bool bearCond3 = (close < senkouA && close < senkouB); // Below Cloud
   bool bearCond4 = (chikou < pastPrice);

   // State Transition
   if(bullCond1 && bullCond2_Spec && bullCond3 && bullCond4)
     {
      if(m_currentState != STATE_BULLISH)
        {
         m_currentState = STATE_BULLISH;
         m_barsInState = 0;
        }
     }
   else if(bearCond1 && bearCond2 && bearCond3 && bearCond4)
     {
      if(m_currentState != STATE_BEARISH)
        {
         m_currentState = STATE_BEARISH;
         m_barsInState = 0;
        }
     }
   // Else remain
  }

//+------------------------------------------------------------------+
//| Helpers                                                          |
//+------------------------------------------------------------------+
double CAdaptiveIchimoku::GetTenkan(int index) { return CalculateMidPrice(m_pTenkan, index); }
double CAdaptiveIchimoku::GetKijun(int index) { return CalculateMidPrice(m_pKijun, index); }

double CAdaptiveIchimoku::GetSenkouA(int index)
  {
   // Senkou A = (Tenkan + Kijun) / 2 shifted forward 26.
   // To get value at 'index' (current time), we look back 26 bars at the T/K calculated then.
   // But wait, Senkou A at Current Time is plotted 26 bars ahead usually?
   // Or is the Cloud at Current Time formed by T/K from 26 bars ago?
   // "Buffer 2: Senkou Span A... shifted +26 bars"
   // This means the value plotted at Time[0] is derived from T/K at Time[26].
   int shift = index + 26;
   double t = CalculateMidPrice(m_pTenkan, shift);
   double k = CalculateMidPrice(m_pKijun, shift);
   return (t + k) / 2.0;
  }

double CAdaptiveIchimoku::GetSenkouB(int index)
  {
   // Senkou B plotted at Time[0] is from High/Low at Time[26] over period 52.
   return CalculateMidPrice(m_pSenkouB, index + 26);
  }

double CAdaptiveIchimoku::GetChikou(int index)
  {
   // Chikou is Close shifted back 26.
   // At Time[0], Chikou is simply Close[0] plotted at Time[26].
   // But for validation "Chikou > Price", we look at Chikou value at Time[26] (which is Close[0])
   // vs Price at Time[26].
   // Implementation: Return Close[index]. The comparison logic handles the shift.
   return iClose(_Symbol, PERIOD_CURRENT, index);
  }

double CAdaptiveIchimoku::GetKumoThickness(int index)
  {
   return MathAbs(GetSenkouA(index) - GetSenkouB(index));
  }

// Helper to get standard iIchimoku for H4 check
double iIchimokuGet(ENUM_TIMEFRAMES period, int buffer, int shift)
  {
   // This creates a handle every call which is bad (non-zero allocation),
   // but for H4 check once per bar it's "okay" or should be optimized.
   // ideally member handle. For brevity:
   static int h4 = INVALID_HANDLE;
   if(h4 == INVALID_HANDLE) h4 = iIchimoku(_Symbol, period, 9, 26, 52);

   double buf[1];
   if(CopyBuffer(h4, buffer, shift, 1, buf) > 0) return buf[0];
   return 0.0;
  }
