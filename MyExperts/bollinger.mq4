//+------------------------------------------------------------------+
//|                                                    bollinger.mq4 |
//|                                                        bollinger |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "bollinger"
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

#include "../../Include/MyInclude/JensUtils.mqh";
extern int myMagic = 20180605;

extern int tracelevel = 2;
extern int bbPeriod = 16;
extern double bbStdDev = 2.5;
extern int trendFollowingEmaPeriod = 60;
extern int rsiPeriod = 6;
extern double rsiThreshold = 18.0;
extern double targetFix = 10.0;
extern double fixLots = 0.1;
extern double maxStop = 0.5;
extern string chartLabel = "";

static datetime lastTradeTime = NULL;
static int lotDigits = 2;


//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
   Comment(chartLabel);
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

   if (Time[0] ==lastTradeTime) return;
   lastTradeTime = Time[0];  
   
   datetime now = TimeCurrent();


   double bbUpper = NormalizeDouble(iBands(Symbol(),PERIOD_CURRENT,period,bbStdDev,0,PRICE_TYPICAL,MODE_UPPER,1),_Digits;
   double bbLower = NormalizeDouble(iBands(Symbol(),PERIOD_CURRENT,period,bbStdDev,0,PRICE_TYPICAL,MODE_LOWER,1),_Digits);
   
   double emaPrev = iMA(_Symbol,PERIOD_CURRENT,trendFollowingEmaPeriod,0,MODE_EMA,PRICE_CLOSE,2);
   double ema = iMA(_Symbol,PERIOD_CURRENT,trendFollowingEmaPeriod,0,MODE_EMA,PRICE_CLOSE,1);
   
   double rsiPrev = iRSI(_Symbol,PERIOD_CURRENT,rsiPeriod,PRICE_CLOSE,2);
   double rsi = iRSI(_Symbol,PERIOD_CURRENT,rsiPeriod,PRICE_CLOSE,1);
   
   closeAllPendingOrders();
      
   double target = targetFix;
   if ( (emaPrev < ema) && 
        countOpenLongPositions()==0 &&
        
        ) {
      double lots=fixLots;
      
      if (lots == 0.0) {
         lots=lotsByRisk(bbUpper-bbMain+stopBuffer,risk,lotDigits);
      }
      double tp = NormalizeDouble(bbUpper+target,Digits());   
      double stop = bbMain-stopBuffer;
      if (bbUpper - stop > maxStop) {
         stop = bbUpper - maxStop;
      }
      OrderSend(Symbol(),OP_BUYSTOP,lots,bbUpper,5,stop,tp,"bolinger",myMagic,0,clrGreen);
   }
  
   if ( (emaPrev > ema) && (countOpenShortPositions() == 0 || currentRisk() <= 0.0)) {
      double lots = fixLots;
      if (lots == 0) {
         lots = lotsByRisk((bbMain+stopBuffer)-bbLower,risk,lotDigits);
      }
      double stop = bbMain+stopBuffer;
      if (stop - bbLower > maxStop) {
         stop = bbLower + maxStop;
      }
      double tp = NormalizeDouble(bbLower-target,Digits());
      OrderSend(Symbol(),OP_SELLSTOP,lots,bbLower,5,stop,tp,"bollinger",myMagic,0,clrRed);
  }
   
  }
//+------------------------------------------------------------------+
