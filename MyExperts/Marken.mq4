//+------------------------------------------------------------------+
//|                                                       Marken.mq4 |
//|                                                           Marken |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Marken"
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict
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

   
  }
//+------------------------------------------------------------------+
//| Timer function                                                   |
//+------------------------------------------------------------------+
void OnTimer()
  {
//---
   string marken = StringFormat("TH=%.2f, TH[1]=%.2f, TT=%.2f, TT[1]=%.2f, C[1]=%.2f, O=%.2f, C[2]=%.2f, O[1]=%.2f",
      iHigh(Symbol(),PERIOD_D1,0),
      iHigh(Symbol(),PERIOD_D1,1),
      iLow(Symbol(),PERIOD_D1,0),
      iLow(Symbol(),PERIOD_D1,1),
      Close[1],
      Open[0],
      Close[2],
      Open[1]);
   Comment(marken);
      
  }
//+------------------------------------------------------------------+
