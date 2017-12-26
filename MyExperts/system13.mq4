//+------------------------------------------------------------------+
//|                                                     system13.mq4 |
//|                                       low stdDev - stay in range |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "low stdDev - stay in range"
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

#include "../Include/JensUtils.mqh";

extern string startTime = "08:00";
extern string endTime = "21:58";
extern int myMagic = 201612201;
extern double baseLots = 1.0;
extern double accountSize = 1000.0;
extern double fixedTakeProfit = 0.0;
extern double initialStop = 20.0;
extern double stopAufEinstandBei = 5.0;
extern int stdDev_period = 16;
extern double stdDev_threshold = 7.0;
extern double trailInProfit = 0.0;
extern int trailWithLastXCandle = 2;
extern int maxMinutes = 10;
extern double bollingDistance = 2.5;

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
   
   
   
   if (trailInProfit>0) trailInProfit(myMagic,trailInProfit);
   if (trailWithLastXCandle>0) trailWithLastXCandle(myMagic,trailWithLastXCandle);
   if (stopAufEinstandBei>0) stopAufEinstand(myMagic,stopAufEinstandBei);
   
   if(lastTradeTime == Time[0]) {
      return;
   } else {
      lastTradeTime = Time[0];
   }
   
   if (maxMinutes > 0) {
      timeout(myMagic,TimeCurrent()-60*maxMinutes);
   }
   
   double standardDeviation =iStdDev(NULL,PERIOD_CURRENT,stdDev_period,0,MODE_SMA,PRICE_CLOSE,0);
   
   if (standardDeviation < stdDev_threshold && currentRisk(myMagic)<=0) {
      double upperBand = iBands(NULL,PERIOD_CURRENT,stdDev_period,bollingDistance,0,PRICE_CLOSE,MODE_UPPER,0);
      double lowerBand = iBands(NULL,PERIOD_CURRENT,stdDev_period,bollingDistance,0,PRICE_CLOSE,MODE_LOWER,0);
      double middleBand = iBands(NULL,PERIOD_CURRENT,stdDev_period,bollingDistance,0,PRICE_CLOSE,MODE_MAIN,0);
      double middleBandPrev =iBands(NULL,PERIOD_CURRENT,stdDev_period,bollingDistance,0,PRICE_CLOSE,MODE_MAIN,1);
      
      if (High[1] > upperBand && 
         Bid < upperBand &&
         middleBand < middleBandPrev) {
         double tp = 0;
         if (fixedTakeProfit >0) tp = Bid - fixedTakeProfit;
         double stop = 0;
         if (trailWithLastXCandle > 0) {
            stop = High[iHighest(NULL,PERIOD_CURRENT,MODE_HIGH,trailWithLastXCandle+1,0)];
         }
         if (stop > Bid+initialStop) stop = Bid+initialStop;
         OrderSend(NULL,OP_SELL,lots(baseLots,accountSize),Bid ,3,stop,tp,NULL,myMagic,0,clrRed);
         
      } else if (Low[1] < lowerBand && 
         Ask > lowerBand &&
         middleBand > middleBandPrev) {
         double tp = 0;
         if (fixedTakeProfit > 0) tp = Ask+fixedTakeProfit;
         double stop = 0;
         if (trailWithLastXCandle > 0) {
            stop = Low[iLowest(NULL,PERIOD_CURRENT,MODE_LOW,trailWithLastXCandle+1,0)];
         }
         if (stop<Ask-initialStop) stop = Ask-initialStop;
         OrderSend(NULL,OP_BUY,lots(baseLots,accountSize),Ask,3,Ask - initialStop,tp,NULL,myMagic,0,clrGreen);
      }
   }
   
   
   
  }
//+------------------------------------------------------------------+
