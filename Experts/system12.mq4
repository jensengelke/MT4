//+------------------------------------------------------------------+
//|                                                     system12.mq4 |
//|                                 Rate Of Change of Moving Average |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Rate Of Change of Moving Average"
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict


#include "../Include/JensUtils.mqh";

extern string startTime = "08:00";
extern string endTime = "21:58";
extern int myMagic = 20161220;
extern int period = 50;
extern double baseLots = 1.0;
extern double accountSize = 1000.0;
extern double fixedTakeProfit = 0.0;
extern double initialStop = 60.0;
extern double stopAufEinstandBei = 5.0;
extern double trailInProfit = 0.0;
extern int trailWithLastXCandle = 0;
extern double absROCThreshold = 0.0001;

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
   
   stopAufEinstand(myMagic,stopAufEinstandBei);
   trailInProfit(myMagic,trailInProfit);
      
   if(lastTradeTime == Time[0]) {
      return;
   } else {
      lastTradeTime = Time[0];
   }
   if (trailWithLastXCandle>0) {
      trailWithLastXCandle(myMagic,trailWithLastXCandle);
   }
  
   double roc = iCustom(NULL,PERIOD_CURRENT,"Jens-ROC-MA",period,0,0);
   //Comment("roc=",roc);
   //Print("roc=",roc);
   
   if (roc == -1.0 || roc > 2.0) return;
   
   if (roc < 1) {
      closeLongPositions(myMagic);  
   }
   
   if (roc > (1+absROCThreshold) && currentRisk(myMagic) <=0) {
      double tp = 0;
      if (fixedTakeProfit > 0) {
         tp = Bid + fixedTakeProfit;
      }
      openLongPosition(myMagic,lots(baseLots,accountSize), Ask,Ask-initialStop,tp);
   }
   
   if (roc > 1) {
      closeShortPositions(myMagic);
   }
   
   if (roc < (1-absROCThreshold) && currentRisk(myMagic) <=0) {
      double tp = 0;
      if (fixedTakeProfit > 0) {
         tp = Ask - fixedTakeProfit;
      }
      openShortPosition(myMagic,lots(baseLots,accountSize), Bid, Bid+initialStop,tp);
   }
  
  }
//+------------------------------------------------------------------+
