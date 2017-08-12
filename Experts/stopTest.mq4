//+------------------------------------------------------------------+
//|                                                     stopTest.mq4 |
//|                                                             Jens |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Jens"
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

extern double riskInPercent = 0.1;
extern double stopDistance = 30.0;

static bool done = false;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- create timer
   EventSetTimer(60);
      
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//--- destroy timer
   EventKillTimer();
      
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//---
   if (!done) {
      for (int i=0;i<50;i++) {
         double price = Ask;
         double equityAtRisk = (i*riskInPercent/100) * AccountEquity();
         double stop = price - stopDistance;
         double lots = equityAtRisk / (stopDistance * MarketInfo(Symbol(),MODE_LOTSIZE));
      
         PrintFormat("lots=%.2f, risk=%.2f, price=%.2f, stop=%.2f,equityAtRisk=%.2f,lotsize=%.2f", lots,(i*riskInPercent),price,stop,equityAtRisk,MarketInfo(Symbol(),MODE_LOTSIZE));
      }
      done = true;
   }
  }
//+------------------------------------------------------------------+
//| Timer function                                                   |
//+------------------------------------------------------------------+
void OnTimer()
  {
//---
   
  }
//+------------------------------------------------------------------+
