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
extern int myMagic = 20180609;

extern int tracelevel = 2;
extern int period = 60;
extern double bbStdDev = 2.7;
extern double stopBuffer = 2.0;
extern double target = 22.0;
extern int exit=2; //exit: 1-middle, 2 opposite bb 
extern double lots = 1.0;
extern double maxStop = 20.0;
extern string chartLabel = "";
extern int startHour =9; //start at Server time
extern int closeHour = 22; //close at Server time + 45 min
static datetime lastTradeTime = NULL;

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
   
   datetime now = TimeCurrent();

   if (TimeHour(now)>=closeHour && TimeMinute(now)>=45) {
      closeAllOpenOrders(myMagic);
      closeAllPendingOrders(myMagic);
      return;
   } else if (TimeHour(now)>=startHour) {
      double stddev = iStdDev(Symbol(),PERIOD_CURRENT,period,0,MODE_SMA,PRICE_TYPICAL,0);
      double bbUpper = NormalizeDouble(iBands(Symbol(),PERIOD_CURRENT,period,bbStdDev,0,PRICE_TYPICAL,MODE_UPPER,0),Digits());
      double bbLower = NormalizeDouble(iBands(Symbol(),PERIOD_CURRENT,period,bbStdDev,0,PRICE_TYPICAL,MODE_LOWER,0),Digits());
      double bbMain = NormalizeDouble(iBands(Symbol(),PERIOD_CURRENT,period,bbStdDev,0,PRICE_TYPICAL,MODE_MAIN,0),Digits());
      
      if (exit==1) {
         trail(myMagic,bbMain,bbMain,false);
      } else if (exit==2) {   
         trail(myMagic,bbUpper,bbLower,false);      
      }
      
      int pendingLongTicket = -1;
      int pendingShortTicket = -1;
      
      for (int i=OrdersTotal();i>=0;i--) {
         OrderSelect(i,SELECT_BY_POS,MODE_TRADES);
         if (OrderMagicNumber() != myMagic) continue;
         if (OrderSymbol() != Symbol()) continue;
         if (OrderType() == OP_BUYSTOP) {
            pendingLongTicket = OrderTicket();
            double tp = NormalizeDouble(bbUpper+target,Digits());   
            double stop = bbMain-stopBuffer;
            if ((bbUpper - stop) > maxStop) {
               stop = bbUpper - maxStop;
            }
            OrderModify(pendingLongTicket,bbUpper,stop,tp,0,clrGreen);
         }
         if (OrderType() == OP_SELLSTOP) {
            pendingShortTicket = OrderTicket();
            double stop = bbMain+stopBuffer;
            if ((stop - bbLower) > maxStop) {
               stop = bbLower + maxStop;
            }
            double tp = NormalizeDouble(bbLower-target,Digits());
            OrderModify(pendingShortTicket,bbLower,stop,tp,0,clrRed);
         }
      }
      
      
      if (pendingLongTicket==-1 && currentRisk(myMagic) <= 0.0) {
         
         double tp = NormalizeDouble(bbUpper+target,Digits());   
         double stop = bbMain-stopBuffer;
         if ((bbUpper - stop) > maxStop) {
            stop = bbUpper - maxStop;
         }
         OrderSend(Symbol(),OP_BUYSTOP,lots,bbUpper,5,stop,tp,"bollinger - " + chartLabel,myMagic,0,clrGreen);
      } 
     
      if (pendingShortTicket==-1 && currentRisk(myMagic) <= 0.0) {
         double stop = bbMain+stopBuffer;
         if ((stop - bbLower) > maxStop) {
            stop = bbLower + maxStop;
         }
         double tp = NormalizeDouble(bbLower-target,Digits());
         OrderSend(Symbol(),OP_SELLSTOP,lots,bbLower,5,stop,tp,"bollinger - " + chartLabel,myMagic,0,clrRed);
     }
     lastTradeTime = Time[0];   
   }
   
   
  }
//+------------------------------------------------------------------+
