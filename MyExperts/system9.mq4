
//+------------------------------------------------------------------+
//|                                                      system9.mq4 |
//|                                                SMA open vs close |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "two EMAs"
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

#include "../Include/JensUtils.mqh";

extern string startTime = "08:00";
extern string endTime = "21:58";
extern int myMagic = 20161127;
extern double baseLots = 1.0;
extern double accountSize = 1000.0;
extern double fixedTakeProfit = 0.0;
extern double initialStop = 60.0;
extern double stopAufEinstandBei = 5.0;
extern double trailInProfit = 30;
extern int emaPeriodSlow = 40;
extern int emaPeriodFast = 7;
extern int  flatPeriod=16;
extern double flatThreshold =1.005;
extern int trailWithCandle = 1;

string screenString = "StatusWindow";
datetime lastcandle = NULL;

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
   
   stopAufEinstand(myMagic, stopAufEinstandBei);
   if (trailInProfit > 0) {
      trailInProfit(myMagic,trailInProfit);
   }
   
   if (lastcandle == Time[0]) {
         return;
   } else {
      lastcandle = Time[0];
   }
   
   if (trailWithCandle>0) {
      trailWithLastXCandle(myMagic,trailWithCandle); 
   }
      
   double slowEMA = iMA(NULL,PERIOD_CURRENT,emaPeriodSlow,0,MODE_EMA,PRICE_CLOSE,0);
   double slowEMAPrev = iMA(NULL,PERIOD_CURRENT,emaPeriodSlow,0,MODE_EMA,PRICE_CLOSE,1);
   
   double fastEMA = iMA(NULL,PERIOD_CURRENT,emaPeriodFast,0,MODE_EMA,PRICE_CLOSE,0);
   double fastEMAPrev = iMA(NULL,PERIOD_CURRENT,emaPeriodFast,0,MODE_EMA,PRICE_CLOSE,1);
   
   double spread = MathAbs(Bid-Ask);
   double minSlowEMA = slowEMA;
   double maxSlowEMA = slowEMA;
   for (int i=1;i<flatPeriod;i++) {
      double ma = iMA (NULL, PERIOD_CURRENT,emaPeriodSlow,0,MODE_EMA,PRICE_CLOSE,i);
      if (ma>maxSlowEMA) maxSlowEMA=ma;
      if (ma<minSlowEMA) minSlowEMA=ma;
   }
   
   double maRatio = maxSlowEMA / minSlowEMA;
   //double rsi = iRSI(NULL,PERIOD_CURRENT,rsiPeriod,PRICE_CLOSE,0);
      
   int direction = currentDirectionOfOpenPositions(myMagic);
   
   if (  slowEMA > fastEMA && 
         slowEMAPrev > fastEMAPrev &&
         fastEMA < fastEMAPrev &&
         slowEMA < slowEMAPrev         
         ) { //downtrend
      if (direction > 0) {
         closeLongPositions(myMagic);
      }
      
      if (currentRisk(myMagic)<=0 && 
         Bid < fastEMA && 
         Close[1] < fastEMA &&
         //(rsi<minBlackOutRSI || rsi > maxBlackOutRSI)
         maRatio > flatThreshold
         ) {      
         openShortPosition();
      }
   } 
   
   if (  slowEMA < fastEMA && 
         slowEMAPrev < fastEMAPrev &&
         slowEMA > slowEMAPrev &&
         fastEMA > fastEMAPrev) { //uptrend
      if (direction < 0) {
         closeShortPositions(myMagic);
      }
      if (  currentRisk(myMagic)<=0 && 
            Ask > fastEMA && 
            Close[1] > fastEMA &&
           // (rsi<minBlackOutRSI || rsi > maxBlackOutRSI)
            maRatio > flatThreshold
            ) {
         openLongPosition();
      }
   }
  
  }
//+------------------------------------------------------------------+
void openLongPosition() {
   OrderSend(NULL,OP_BUY,lots(baseLots,accountSize),Ask,3,Ask - initialStop,0,NULL,myMagic,0,clrGreen);
}

void openShortPosition() {
   OrderSend(NULL,OP_SELL,lots(baseLots,accountSize),Bid ,3,Bid+initialStop,0,NULL,myMagic,0,clrGreen);
}