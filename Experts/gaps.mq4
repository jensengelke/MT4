//+------------------------------------------------------------------+
//|                                                         gaps.mq4 |
//|                                                             gaps |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "gaps"
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict
#property strict#include "../Include/JensUtils.mqh";
extern int myMagic = 20170708;

extern double minGap = 10.0;
extern double maxGap = 50.0;
extern double risk = 1.0;

static datetime lastTradeTime = NULL;
static int symbolDigits = -1;
static int lotDigits = -1;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- create timer
   EventSetTimer(60);
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
//--- destroy timer
   EventKillTimer();
      
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//---
   PrintFormat("heute um 8: %s",todayAt("08:00"));
   
   PrintFormat("gestern um 17:30: %s", yesterdayAt("17:30"));
  }
//+------------------------------------------------------------------+
//| Timer function                                                   |
//+------------------------------------------------------------------+
void OnTimer()
  {
//---
   
  }
//+------------------------------------------------------------------+
