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
extern int myMagic = 20180622;

extern int tracelevel = 2;
extern double stdDevPeriod = 48;
extern double targetFix = 22.0;
extern double entryStddev = 4.0;
extern double targetStddev = 5.0;
extern double stopStddev = 3.0;
extern double lots = 1.0;
extern double maxStop = 20.0;
extern double trailingStop = 10.0;
extern string chartLabel = "";
extern int startHour =9; //start at Server time
extern int closeHour = 22; //close at Server time + 45 min
extern double maxSpread = 2.0;
static datetime lastTradeTime = NULL;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
   Comment(chartLabel);
   if (stopStddev >= entryStddev) return(INIT_PARAMETERS_INCORRECT);
   if (targetStddev <= entryStddev) return(INIT_PARAMETERS_INCORRECT);
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

   datetime now = TimeCurrent();
   if ((TimeHour(now)>=closeHour && TimeMinute(now)>=45) ||
      (MathAbs(Bid-Ask)>maxSpread) ) {
      closeAllOpenOrders(myMagic);
      closeAllPendingOrders(myMagic);
      return;
   }
   
   if (Time[0] ==lastTradeTime) return;
   

   if (TimeHour(now)<startHour) return;
   
   if (trailingStop > 0.0) trailInProfit(myMagic,trailingStop);

   double stddev = iStdDev(Symbol(),PERIOD_CURRENT,stdDevPeriod,0,MODE_SMA,PRICE_TYPICAL,0);
   
   int pendingLongTicket = -1;
   int pendingShortTicket = -1;
   double entry = NormalizeDouble(entryStddev * stddev,Digits());
   double stop = NormalizeDouble(stopStddev * stddev,Digits());
   if (stop > maxStop) stop = maxStop;
  
   double tp = NormalizeDouble(targetStddev*stddev,Digits());   
   if (targetFix > 0.0) tp = targetFix;
         
   for (int i=OrdersTotal();i>=0;i--) {
      OrderSelect(i,SELECT_BY_POS,MODE_TRADES);
      if (OrderMagicNumber() != myMagic) continue;
      if (OrderSymbol() != Symbol()) continue;
      if (OrderType() == OP_BUYSTOP) {
         pendingLongTicket = OrderTicket();
         OrderModify(pendingLongTicket,Ask + entry,Ask - stop,Ask + tp,0,clrGreen);
      }
      if (OrderType() == OP_SELLSTOP) {
         pendingShortTicket = OrderTicket();            
         OrderModify(pendingShortTicket,Bid - entry,Bid + stop,Bid - tp,0,clrRed);
      }
   }
   
   
   if (pendingLongTicket==-1 && currentRisk(myMagic) <= 0.0) {
      OrderSend(Symbol(),OP_BUYSTOP,lots,Ask + entry,5,Ask - stop,Ask + tp,"Mitspringer - " + chartLabel,myMagic,0,clrGreen);
   } 
  
   if (pendingShortTicket==-1 && currentRisk(myMagic) <= 0.0) {
      OrderSend(Symbol(),OP_SELLSTOP,lots,Bid - entry,5,Bid + stop,Bid - tp,"Mitspringer - " + chartLabel,myMagic,0,clrRed);
  }
  lastTradeTime = Time[0];   
   
  }
//+------------------------------------------------------------------+
