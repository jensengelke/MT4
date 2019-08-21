//+------------------------------------------------------------------+
//|                                                supertrend-ea.mq4 |
//|                                                    supertrend-ea |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "supertrend-ea"
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

extern double multiplier = 5.0;
extern int    period = 12;
datetime lastBar = NULL;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
   
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---
   
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
   
   if (Time[1] == lastBar) return;
   lastBar = Time[1];
   
   int trend = 0;
   double upper = 0.0;
   double lower = 0.0;
   
   double ST3upper = (High[3] + Low[3])/2 + (iATR(_Symbol,PERIOD_CURRENT,period,3) * multiplier);
   double ST3lower = (High[3] + Low[3])/2 - (iATR(_Symbol,PERIOD_CURRENT,period,3) * multiplier);
   if (Close[3] >= ST3upper) 
      trend = 1; 
   else 
      trend = -1;
      
   upper
   double ST2 = (High[2] + Low[2])/2 + (iATR(_Symbol,PERIOD_CURRENT,period,2) * multiplier * trend);
   if (Close[2] >= ST2 && t
   
   
   double ST1 = (High[1] + Low[1])/2 + (iATR(_Symbol,PERIOD_CURRENT,period,1)*multiplier);
   
   if (Close[2] > lastST && Close[1] < currentST) {
      PrintFormat("crossing short");
   } 
   
   if (Close[2] < lastST && Close[

   
   PrintFormat("Close[1]: %.5f, lastTrendUp: %.5f, lastTrendDown: %5f", Close[1], stTrendUp, stTrendDown);
  }
//+------------------------------------------------------------------+

void longSignal(double st) {
   PrintFormat("long signal st=%.5f", st);
}

void shortSignal(double st) {
   PrintFormat("short signal st=%.5f", st);
}