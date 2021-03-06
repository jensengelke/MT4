//+------------------------------------------------------------------+
//|                                                    both-ways.mq4 |
//|                                                        Both Ways |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Both Ways"
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

#include "../../Include/MyInclude/JensUtils.mqh";
extern int myMagic = 20180318;

extern int tracelevel = 2;
extern int lookBackPeriod = 12;
extern int tradeStartHour = 9;
extern int tradeEndHour = 21;
extern double minRangeInLookbackPerdiod = 30.0;
extern double minStop = 30.0;
extern double maxTarget = 10.0;
extern double risk = 5.0;
extern int trailPeriod = 3;
extern double extremeRatio = 0.2; //Kein Handel, wenn der Schlusskurs 0.x vom Kerzenextrem entfernt ist
extern double targetRatio = 0.3; //Target relativ zur Range

static datetime lastTradeTime = NULL;
static int lotDigits = 1;


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
   if (Time[0] ==lastTradeTime) return;
   lastTradeTime = Time[0];   
   
   datetime now = TimeCurrent();

   if (TimeHour(now)>=21 && TimeMinute(now)>=45) {
      closeAllOpenOrders(myMagic);
      return;
   } else if (TimeMinute(now)== 0) {
   //TODO: lieber anpassen als schließen
         trailWithLastXCandle(myMagic,trailPeriod);
         
         if (TimeHour(now) < tradeStartHour) return;
         if (TimeHour(now) > tradeEndHour) return;
   
         double recentHigh = High[iHighest(Symbol(),PERIOD_CURRENT,MODE_HIGH,lookBackPeriod,0)];
         double recentLow = Low[iLowest(Symbol(),PERIOD_CURRENT,MODE_LOW,lookBackPeriod,0)];
         double open = Open[lookBackPeriod];
         double close = Close[lookBackPeriod];
         
         double range = (recentHigh - recentLow);
         Comment("Range: " + range);
         if (minRangeInLookbackPerdiod > range) return;
         
         if ((recentHigh - close) < (extremeRatio*range)) return;
         if ((close - recentLow) < (extremeRatio*range)) return;
         
         if (countOpenLongPositions(myMagic)==0) {
            double stop = recentLow;
            if ((Ask-stop)<minStop) stop = Ask - minStop;
            double target = Ask+(targetRatio*range);
            if ((target - Ask)>maxTarget) target = Ask + maxTarget;
            double lots = lotsByRisk(Ask - stop,risk,lotDigits);
            
            OrderSend(Symbol(),OP_BUY,lots,Ask,5,stop,target,NULL,myMagic,0,clrGreen);
         }
         
         if (countOpenShortPositions(myMagic)==0) {
            double stop = recentHigh;
            if ((stop-Bid)<minStop) stop = Bid + minStop;
            double target = Bid-(targetRatio*range);
            if ((Bid - target)>maxTarget) target = Bid - maxTarget;
            double lots = lotsByRisk(stop-Bid,risk,lotDigits);
            
            OrderSend(Symbol(),OP_SELL,lots,Bid,5,stop,target,NULL,myMagic,0,clrGreen);
         }
   }
   
   
  }
//+------------------------------------------------------------------+
