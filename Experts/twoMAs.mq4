//+------------------------------------------------------------------+
//|                                                       twoMAs.mq4 |
//|                                                             Jens |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Jens"
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict


#include "../Include/JensUtils.mqh";


extern string startTime = "08:00";
extern string endTime = "21:58";
extern int myMagic = 20170505;
extern double stopAufEinstandBei = 15.0;
extern double riskInPercent = 1.0;
extern double bandWidth = 60.0;

extern int fastEMAperiod = 8;
extern int slowSMAperiod = 40;

extern bool trace = false;

static int lastMinutes = -1;


//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
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
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//---
   //abort at night
   if (!isHandelszeit(startTime,endTime)) {
  //    closeAllOpenOrders(myMagic);
      return;
   }   
      
   //act at most once per minute
   if ( TimeMinute(TimeCurrent()) != lastMinutes) {
      lastMinutes = TimeMinute(TimeCurrent());
   } else {
      return;
   }
   
   double sma = iMA(Symbol(),PERIOD_CURRENT,slowSMAperiod,0,MODE_SMA,PRICE_CLOSE,1);
   double ema = iMA(Symbol(),PERIOD_CURRENT,fastEMAperiod,0,MODE_EMA,PRICE_CLOSE,1);
   
   if (currentDirectionOfOpenPositions(myMagic) > 0) {
      double stop = (sma - bandWidth);
      if (trace) {
         PrintFormat("trailing long: sma=%.2f, bandwidth=%.2f, stop = %.2f",sma,bandWidth,stop);
      }
      trailWithMA(myMagic,stop);
   } else if (currentDirectionOfOpenPositions(myMagic)<0) {
      trailWithMA(myMagic,(sma + bandWidth));
   } else {
      double prevSma = iMA(Symbol(),PERIOD_CURRENT,slowSMAperiod,0,MODE_SMA,PRICE_CLOSE,2);
      double prevEma = iMA(Symbol(),PERIOD_CURRENT,fastEMAperiod,0,MODE_EMA,PRICE_CLOSE,2);
      if (ema > prevEma && sma > prevSma && Ask > sma) {
         double price = Ask;
         double stop = price - (sma - bandWidth) ;
         if (trace) {
            PrintFormat("calculateing stop for buy: Ask=%.2f, sma=%.2f, bandWidth=%.2f, stopDistance=%.2f",Ask,sma,bandWidth,stop);
         }
         double lots = lotsByRisk(stop,riskInPercent,1);
         if (trace) {
            PrintFormat("buying %.1f lots at %.2f with stop at %.2f", lots,Ask,sma);
         }
         OrderSend(Symbol(),OP_BUY,lots,Ask,3,sma - bandWidth,0,NULL,myMagic,0,clrGreen);
      }
      if (ema < prevEma && sma < prevSma && Bid < sma) {
         double price = Bid;
         double stop = (sma+bandWidth)-Bid;
         if (trace) {
            PrintFormat("calculateing stop for sell: Bid=%.2f, sma=%.2f, bandWidth=%.2f, stopDistance=%.2f",Bid,sma,bandWidth,stop);
         }
         double lots = lotsByRisk(stop,riskInPercent,1);
         if (trace) {
            PrintFormat("selling %.1f lots at %.2f with stop at %.2f", lots,Bid,sma);
         }
         OrderSend(Symbol(),OP_SELL,lots,Bid,3,sma + bandWidth,0,NULL,myMagic,0,clrRed);      
      }
   }
   
  }
//+------------------------------------------------------------------+
//| Timer function                                                   |
//+------------------------------------------------------------------+
void OnTimer()
  {
   if (!isHandelszeit(startTime,endTime)) {
   //      closeAllOpenOrders(myMagic);
      return;
   }   
  }
//+------------------------------------------------------------------+
