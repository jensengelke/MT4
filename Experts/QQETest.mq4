//+------------------------------------------------------------------+
//|                                                      QQETest.mq4 |
//|                                                              QQE |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "QQE"
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

#include "../Include/JensUtils.mqh";

extern string startTime = "08:00";
extern string endTime = "21:58";
extern int myMagic = 20161225;
extern int period = 60;
extern double buffer = 3.0;
extern double baseLots = 0.1;
extern double accountSize = 1000.0;
extern double initialStop = 0.001;
extern double fixedTP = 20.0;

static datetime lastTradeTime = NULL;

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
    if (!isHandelszeit(startTime,endTime)) {
         closeAllPendingOrders(myMagic);
         closeAllOpenOrders(myMagic);
      return;
   }
   
   if(lastTradeTime == Time[0]) {
      return;
   } else {
      lastTradeTime = Time[0];
   }
   
   double dottedLine = iCustom(NULL,PERIOD_CURRENT,"QQE",period,1,0);
   double solidLine = iCustom(NULL,PERIOD_CURRENT,"QQE",period,0,0);
   
   if (solidLine > dottedLine) closeShortPositions(myMagic);
   if (solidLine < dottedLine) closeLongPositions(myMagic);
   
   
   if (solidLine > dottedLine + buffer) {
      
      if (OrdersTotal()==0) {
         openLongPosition(myMagic,lots(baseLots,accountSize),Ask,Ask-initialStop,Ask+fixedTP);
      }
   } 
   
   if (solidLine < dottedLine - buffer)  {
      if (OrdersTotal()==0) {
         openShortPosition(myMagic,lots(baseLots,accountSize),Bid,Bid+initialStop,Bid-fixedTP);
      }
   } 
   
      
  }
//+------------------------------------------------------------------+
