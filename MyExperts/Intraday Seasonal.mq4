//+------------------------------------------------------------------+
//|                                            Intraday Seasonal.mq4 |
//|                                                          DerJens |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "DerJens"
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

#include "../../Include/MyInclude/JensUtils.mqh";
extern int myMagic = 20180608;

extern int tracelevel = 2;
extern int direction=2; //exit: 0-short, 1 long
extern double lots = 0.1;
extern string chartLabel = "";
extern int entryHour = 10;
extern int entryMin = 0;
extern int exitHour = 14;
extern int exitMin = 0;
extern int smaFilterPeriods = 8;
extern bool counterTrend = true;
extern int targetPoints = 100;
extern int stopPoints = 200;
int smaFilterPeriod = 1;
extern bool holdOverWeekend = true;

static datetime lastTradeTime = NULL;


//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
   //if (exitHour < entryHour) return(INIT_PARAMETERS_INCORRECT);
   //if (exitHour == entryHour && entryMin >= exitMin) return(INIT_PARAMETERS_INCORRECT);
   
   smaFilterPeriod = 0;
   if (smaFilterPeriods>0) {
      MathPow(2,smaFilterPeriods);
   } 
   
   PrintFormat("initialized with smaFilterPeriod=%i",smaFilterPeriod);
   Comment("%s - SMA: %i",chartLabel,smaFilterPeriod);
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
   
   
   double sma = iMA(Symbol(),PERIOD_D1,smaFilterPeriod,0,MODE_SMA,PRICE_CLOSE,0);
   datetime now = TimeCurrent();
   
   int numberOfPositions = 0;
   if (direction == 0) numberOfPositions = countOpenShortPositions();
   if (direction == 1) numberOfPositions = countOpenLongPositions();

   if (TimeHour(now)==entryHour &&
      TimeMinute(now)==entryMin &&
      numberOfPositions==0) {
         bool weekDayFilter = true;
         
         if (DayOfWeek() == 5 && !holdOverWeekend) weekDayFilter = false;
         bool smaFilter = (smaFilterPeriods > 0);
         if (counterTrend && Ask > sma && direction==0) smaFilter = true;
         if (!counterTrend && Ask < sma && direction==0) smaFilter = true;
         if (counterTrend && Ask < sma && direction==1) smaFilter = true;
         if (!counterTrend && Ask > sma && direction==1) smaFilter = true;
         
         
         if (smaFilter && weekDayFilter) {
            if (direction == 0) {
               double stop = NormalizeDouble(Ask + (stopPoints * _Point),Digits());
               double tp = NormalizeDouble(Bid - (targetPoints * _Point), Digits());
               PrintFormat("Ask: %.5f, stop=%.5f, tp=%.5f",Ask,stop);
               OrderSend(Symbol(),OP_SELL, lots,Bid,50, stop, tp,"intraday seasonal",myMagic,0,clrRed);
            } else if (direction == 1) {
               double stop = NormalizeDouble(Ask - (stopPoints * _Point),Digits());
               double tp = NormalizeDouble(Bid + (targetPoints * _Point), Digits());
               PrintFormat("Ask: %.5f, stop=%.5f, tp=%.5f",Ask,stop);
               OrderSend(Symbol(),OP_BUY, lots,Ask,50, stop, tp,"intraday seasonal",myMagic,0,clrGreen);
            }
         }
   }
   
   if (TimeHour(now)==exitHour && TimeMinute(now)>=exitMin) {
      closeAllOpenOrders();
   }
  }
//+------------------------------------------------------------------+
