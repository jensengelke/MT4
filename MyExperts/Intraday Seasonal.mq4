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
extern double lots = 0.1;
extern string chartLabel = "intraday seasonal";
extern int direction_mon = 0; //0-short, 1 long
extern int entryHour_mon = 10;
extern int entryMin_mon = 0;
extern int exitHour_mon = 14;
extern int exitMin_mon = 0;
extern int direction_tue = 0; //0-short, 1 long
extern int entryHour_tue = 10;
extern int entryMin_tue = 0;
extern int exitHour_tue = 14;
extern int exitMin_tue = 0;
extern int direction_wed = 0; //0-short, 1 long
extern int entryHour_wed = 10;
extern int entryMin_wed = 0;
extern int exitHour_wed = 14;
extern int exitMin_wed = 0;
extern int direction_thu = 0; //0-short, 1 long
extern int entryHour_thu = 10;
extern int entryMin_thu = 0;
extern int exitHour_thu = 14;
extern int exitMin_thu = 0;
extern int direction_fri= 0; //0-short, 1 long
extern int entryHour_fri = 10;
extern int entryMin_fri = 0;
extern int exitHour_fri = 14;
extern int exitMin_fri = 0;

extern double stoploss = 60.0;
extern double target   = 60.0;
extern double trailingstop = 30.0;
static datetime lastTradeTime = NULL;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
   if (trailingstop > target) return (INIT_PARAMETERS_INCORRECT);
  
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
   
   trail(NormalizeDouble(Ask + trailingstop,_Digits), NormalizeDouble(Bid - trailingstop, _Digits),true);
   
   int entryHour = -1;
   int entryMin = -1;
   int exitHour = -1;
   int exitMin = -1;
   int direction = -1;
   
   if (DayOfWeek() == 1) {
      entryHour = entryHour_mon;
      entryMin  = entryMin_mon;
      exitHour  = exitHour_mon;
      exitMin   = exitMin_mon;
      direction = direction_mon;
   } else if (DayOfWeek() == 2) {
      entryHour = entryHour_tue;
      entryMin  = entryMin_tue;
      exitHour  = exitHour_tue;
      exitMin   = exitMin_tue;
      direction = direction_tue;
   } else if (DayOfWeek() == 3) {
      entryHour = entryHour_wed;
      entryMin  = entryMin_wed;
      exitHour  = exitHour_wed;
      exitMin   = exitMin_wed;
      direction = direction_wed;
   } else if (DayOfWeek() == 4) {
      entryHour = entryHour_thu;
      entryMin  = entryMin_thu;
      exitHour  = exitHour_thu;
      exitMin   = exitMin_thu;  
      direction = direction_thu; 
   } else if (DayOfWeek() == 5) {
      entryHour = entryHour_fri;
      entryMin  = entryMin_fri;
      exitHour  = exitHour_fri;
      exitMin   = exitMin_fri;
      direction = direction_fri;
   }
   
   int numberOfPositions = 0;
   if (direction == 0) numberOfPositions = countOpenShortPositions();
   if (direction == 1) numberOfPositions = countOpenLongPositions();
   
   
   if (TimeHour(now)==entryHour &&
      TimeMinute(now)==entryMin &&
      numberOfPositions==0) {
      if (direction == 0) {
         double stop = NormalizeDouble(Ask + stoploss,Digits());
         double tp = NormalizeDouble(Bid - target, Digits());
         PrintFormat("Ask: %.5f, stop=%.5f, tp=%.5f",Ask,stop);
         OrderSend(Symbol(),OP_SELL, lots,Bid,50, stop, tp,"intraday seasonal",myMagic,0,clrRed);
      } else if (direction == 1) {
         double stop = NormalizeDouble(Ask - stoploss,Digits());
         double tp = NormalizeDouble(Bid + target, Digits());
         PrintFormat("Ask: %.5f, stop=%.5f, tp=%.5f",Ask,stop);
         OrderSend(Symbol(),OP_BUY, lots,Ask,50, stop, tp,"intraday seasonal",myMagic,0,clrGreen);
      }
   
   }
   
   if (TimeHour(now)==exitHour && TimeMinute(now)>=exitMin) {
      closeAllOpenOrders();
   }
  }
//+------------------------------------------------------------------+
