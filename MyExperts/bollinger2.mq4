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
extern int myMagic = 20180630;

extern int tracelevel = 2;
extern int period = 16;
extern double bbStdDev = 2.5;
extern double stopBuffer = 0.0;
extern double targetFix = 10.0;
extern double targetStdDev = 1.0;
extern double risk = 2.0;
extern double maxStdDev = 50.0;
extern int exit=1; //exit: 1-middle, 2 opposite bb 
extern double fixLots = 1.0;
extern double maxStop = 20.0;
extern string chartLabel = "";
extern double maxSpread = 2.0;

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

   if ((TimeHour(now)>=21 && TimeMinute(now)>=45) ||
      (MathAbs(Bid-Ask)>maxSpread) ) {
      closeAllOpenOrders(myMagic);
      closeAllPendingOrders(myMagic);
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
      int pendingLongTicket = -1;
      int pendingShortTicket = -1;
      
      double target = targetFix;
      if (targetStdDev!=0.0) {
         target = targetStdDev * stddev;
      }
      
      //long params
      double tpLong = NormalizeDouble(bbUpper+target,Digits());   
      double stopLong = bbMain-stopBuffer;
      if ((bbUpper - stopLong) > maxStop) {
         stopLong = bbUpper - maxStop;
      }
      double lotsLong=fixLots;     
      if (lotsLong == 0.0) {
         lotsLong=lotsByRisk(bbUpper-stopLong,risk,lotDigits);
      }
      
      //short params
      double stopShort = bbMain+stopBuffer;
      if ((stopShort - bbLower) > maxStop) {
         stopShort = bbLower + maxStop;
      }
      double tpShort = NormalizeDouble(bbLower-target,Digits());
      
      double lotsShort=fixLots;     
      if (lotsShort == 0.0) {
         lotsShort=lotsByRisk(stopShort-bbLower,risk,lotDigits);
      }
      
      for (int i=OrdersTotal();i>=0;i--) {
         OrderSelect(i,SELECT_BY_POS,MODE_TRADES);
         if (OrderMagicNumber() != myMagic) continue;
         if (OrderSymbol() != Symbol()) continue;
         if (OrderType() == OP_BUYSTOP) {
            pendingLongTicket = OrderTicket();
            if (lotsLong == OrderLots()) {
               OrderModify(pendingLongTicket,bbUpper,stopLong,tpLong,0,clrGreen);
            } else {
               OrderDelete(pendingLongTicket);
               pendingLongTicket = OrderSend(Symbol(),OP_BUYSTOP,lotsLong,bbUpper,5,stopLong,tpLong,"bollinger - " + chartLabel,myMagic,0,clrGreen);
            }
         }
         if (OrderType() == OP_SELLSTOP) {
            pendingShortTicket = OrderTicket();
            
            if (lotsShort == OrderLots()) {
               OrderModify(pendingShortTicket,bbLower,stopShort,tpShort,0,clrRed);
            } else {
               OrderDelete(pendingShortTicket);
               pendingShortTicket =OrderSend(Symbol(),OP_SELLSTOP,lotsShort,bbLower,5,stopShort,tpShort,"bollinger - " + chartLabel,myMagic,0,clrRed);
            }
         }
      }
      
      
      if (pendingLongTicket==-1 && currentRisk(myMagic) <= 0.0) {
         OrderSend(Symbol(),OP_BUYSTOP,lotsLong,bbUpper,5,stopLong,tpLong,"bollinger - " + chartLabel,myMagic,0,clrGreen);
      } 
     
      if (pendingShortTicket==-1 && currentRisk(myMagic) <= 0.0) {
         OrderSend(Symbol(),OP_SELLSTOP,lotsShort,bbLower,5,stopShort,tpShort,"bollinger - " + chartLabel,myMagic,0,clrRed);
     }
     lastTradeTime = Time[0];   
   }
  }
//+------------------------------------------------------------------+
