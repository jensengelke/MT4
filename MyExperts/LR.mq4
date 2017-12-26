//+------------------------------------------------------------------+
//|                                                           LR.mq4 |
//|                                                               LR |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "LR"
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

#include "../Include/JensUtils.mqh";


extern string startTime = "00:05";
extern string endTime = "23:58";
extern double lrPeriod = 12;
extern double riskInPercent = 1.0;
int lotDigits = -1;
extern int myMagic = 2017000606;
extern double lowerRSquare = 5.0;
extern double upperRSquare = 80.0;
static datetime lastTradeTime = NULL;


//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
      EventSetTimer(60);
   double lotstep = MarketInfo(Symbol(),MODE_LOTSTEP);
   if (lotstep == 1.0)        lotDigits = 0;
   if (lotstep == 0.1)        lotDigits = 1;
   if (lotstep == 0.01)       lotDigits = 2;
   if (lotstep == 0.001)      lotDigits = 3;
   if (lotstep == 0.0001)     lotDigits = 4;
   if (lotDigits == -1)       return(INIT_FAILED);   
   
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
//---
      if (!isHandelszeit(startTime,endTime)) {
         closeAllPendingOrders(myMagic);
         closeAllOpenOrders(myMagic);
      return;
   }
   
   double lr=iCustom(NULL,PERIOD_CURRENT,"LinearRegSlope_v1",0,20,1,0);
   Comment("lr="+lr);
 
  }
//+------------------------------------------------------------------+
