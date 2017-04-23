//+------------------------------------------------------------------+
//|                                           scalp_antizyklisch.mq4 |
//|                                                             Jens |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Jens"
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

#include "../Include/JensUtils.mqh";

extern string startTime = "08:15";
extern string endTime = "20:58";
extern int myMagic = 20170313;
extern double trailInProfit = 5.0;
extern double riskInPercent = 2.0;
extern double buffer = 2.0;
extern int rangePeriod = 30;
extern double stopAufEinstand = 3.0;
extern double maxVola = 30.0;

string screenString = "StatusWindow";
static datetime lastTradeTime = NULL;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
   //if (3*buffer > maxVola-5) return INIT_FAILED;
  
  
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

void OnTimer()
  {
//---
   if (!isHandelszeit(startTime,endTime)) {
      closeAllOpenOrders(myMagic);
      closeAllPendingOrders(myMagic);
   }
   
  }
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//---
      if (!isHandelszeit(startTime,endTime)) {
      return;
   }
   
   int openShortOrderTicket = 0;
   int openLongOrderTicket  = 0;
   
   if (0 < OrdersTotal()) {
      for (int i=OrdersTotal();i>=0;i--) {
         OrderSelect(i,SELECT_BY_POS,MODE_TRADES);
         if (OrderMagicNumber() != myMagic) continue;
         if (OrderSymbol() != Symbol()) continue;
         
         if (OrderType() == OP_BUY) {
            openLongOrderTicket = OrderTicket();
         } else if (OrderType() == OP_SELL) {
            openShortOrderTicket = OrderTicket();
         } 
      }
   }
   
   double rangeTop = getRangeTop();
   double rangeBottom = getRangeBottom();
   bool boring = (rangeTop-rangeBottom)<maxVola;
   
   if (0 < trailInProfit) {
      trailInProfit(myMagic,trailInProfit);
   }
   
   if (0 < stopAufEinstand) {
      stopAufEinstand(myMagic,stopAufEinstand);
   }
   
   if (
      (0 == openShortOrderTicket) && 
      (boring) && 
      (Bid > (rangeTop - ((rangeTop - rangeBottom)/5))) &&
      (Bid < rangeTop - buffer)) {
         double orderLots = lotsByRiskFreeMargin(riskInPercent,(rangeTop-Bid)+buffer);
         openShortPosition(myMagic, orderLots,Bid,rangeTop + buffer, rangeBottom + buffer,"stay in range");
   }
   
   if (
      (0 == openLongOrderTicket) && 
      (boring) && 
      (Ask < (rangeBottom + ((rangeTop - rangeBottom)/5))) &&
      (Ask > rangeBottom + buffer)) {
         double orderLots = lotsByRiskFreeMargin(riskInPercent,(Ask-rangeBottom)+buffer);
         openLongPosition(myMagic, orderLots,Ask,rangeBottom-buffer, rangeTop - buffer,"stay in range");
      
   }
}

double getRangeTop() {
   return High[iHighest(Symbol(),PERIOD_CURRENT,MODE_HIGH, rangePeriod,0)];
}

double getRangeBottom() {
   return Low[iLowest(Symbol(),PERIOD_CURRENT,MODE_LOW,rangePeriod,0)];
}