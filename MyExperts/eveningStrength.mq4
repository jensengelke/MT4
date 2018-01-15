//+------------------------------------------------------------------+
//|                                              eveningStrength.mq4 |
//|                        Copyright 2017, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2017, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict
#include "../../Include/MyInclude/JensUtils.mqh";
extern int myMagic = 20171126;

extern double risk = 1.0;
extern int fixedLots = 0.0;
extern bool trace = true;

extern double initialStop = 20.0;
extern double takeProfit = 30.0;

static datetime lastTradeTime = NULL;
static int symbolDigits = -1;
static int lotDigits = -1;
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
  double lotstep = MarketInfo(Symbol(),MODE_LOTSTEP);
   if (lotstep == 1.0)        lotDigits = 0;
   if (lotstep == 0.1)        lotDigits = 1;
   if (lotstep == 0.01)       lotDigits = 2;
   if (lotstep == 0.001)      lotDigits = 3;
   if (lotstep == 0.0001)     lotDigits = 4;
   if (lotDigits == -1)       return(INIT_FAILED);   
//---

   symbolDigits = MarketInfo(Symbol(),MODE_DIGITS);
   PrintFormat("initialized with lotDigits=%i and symboleDigits=%i",lotDigits,symbolDigits);
   
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
//---
   if(DayOfWeek()==0 || DayOfWeek()==6) return;
 
  // if (Time[0] == lastTradeTime) {
  //    return;
 //  }
 //  lastTradeTime = Time[0];
   
   if (TimeHour(TimeLocal())==09 && TimeMinute(TimeLocal())==00 && currentDirectionOfOpenPositions(myMagic)==0) {
      double lots = fixedLots;
      if (fixedLots == 0.0) {
         lots = lotsByRisk(initialStop,risk,lotDigits);
      }
      double stop = Ask - initialStop;
      double tp = Ask + takeProfit;
      OrderSend(Symbol(),OP_BUY,lots,Ask,3,stop,tp,"evening strength",myMagic,0,clrGreen);
   }
   
   if (TimeHour(TimeLocal()) == 15 && TimeMinute(TimeLocal())==15) {
      closeLongPositions(myMagic);
   }
   
  }
//+------------------------------------------------------------------+
