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
extern int period = 16;
extern double bbStdDev = 2.5;
extern double stopBuffer = 0.0;
extern double targetFix = 10.0;
extern double targetStdDev = 1.0;
extern double risk = 2.0;
extern double maxStdDev = 20.0;
extern int exit=1; //exit: 1-middle, 2 opposite bb 
extern double fixLots = 1.0;
extern double maxStop = 20.0;
extern string chartLabel = "";

static datetime lastTradeTime = NULL;
static int lotDigits = 1;


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

   if (TimeHour(now)>=21 && TimeMinute(now)>=45) {
      closeAllOpenOrders(myMagic);
      return;
   } else if (TimeHour(now)>8) {
      double stddev = iStdDev(Symbol(),PERIOD_CURRENT,period,0,MODE_SMA,PRICE_TYPICAL,0);
      double bbUpper = NormalizeDouble(iBands(Symbol(),PERIOD_CURRENT,period,bbStdDev,0,PRICE_TYPICAL,MODE_UPPER,0),Digits());
      double bbLower = NormalizeDouble(iBands(Symbol(),PERIOD_CURRENT,period,bbStdDev,0,PRICE_TYPICAL,MODE_LOWER,0),Digits());
      double bbMain = NormalizeDouble(iBands(Symbol(),PERIOD_CURRENT,period,bbStdDev,0,PRICE_TYPICAL,MODE_MAIN,0),Digits());
      
      if (exit==1) {
         trail(myMagic,bbMain,bbMain,false);
      } else if (exit==2) {   
         trail(myMagic,bbUpper,bbLower,false);      
      }
      closeAllPendingOrders(myMagic);
         
      if (stddev < maxStdDev) {   
      
         double target = targetFix;
         if (targetStdDev!=0.0) {
            target = targetStdDev * stddev;
         }
         if (countOpenLongPositions(myMagic)==0 || currentRisk(myMagic) <= 0.0) {
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
        
         if (countOpenShortPositions(myMagic) == 0 || currentRisk(myMagic) <= 0.0) {
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
   }
  }
//+------------------------------------------------------------------+
