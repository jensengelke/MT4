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
extern int smaFilterPeriods = 200;
extern bool counterTrend = true;
int smaFilterPeriod = 1;

static datetime lastTradeTime = NULL;


//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
   if (exitHour < entryHour) return(INIT_PARAMETERS_INCORRECT);
   if (exitHour == entryHour && entryMin >= exitMin) return(INIT_PARAMETERS_INCORRECT);
   
   for (int i=0;i<smaFilterPeriods;i++) smaFilterPeriod *=2;
   
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
   

   if (TimeHour(now)==entryHour &&
      TimeMinute(now)==entryMin &&
      countOpenShortPositions(myMagic)==0) {
         bool smaFilter = false;
         if (counterTrend && Ask > sma) smaFilter = true;
         if (!counterTrend && Ask < sma) smaFilter = true;
         
         if (smaFilter) {
            double stop = NormalizeDouble(1.01* Ask,Digits());
            double tp = NormalizeDouble(0.99 * Bid, Digits());
            PrintFormat("Ask: %.5f, stop=%.5f, tp=%.5f",Ask,stop);
            OrderSend(Symbol(),OP_SELL, lots,Bid,5, stop, 0,"intraday seasonal",myMagic,0,clrRed);
         }
   }
   
   if (countOpenShortPositions(myMagic)!=0 &&
      ((TimeHour(now)==exitHour && TimeMinute(now)>=exitMin) || (TimeHour(now)>exitHour))
   ) {
      closeAllOpenOrders(myMagic);
   }
  }
//+------------------------------------------------------------------+
