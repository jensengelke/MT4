//+------------------------------------------------------------------+
//|                                                  BuyStrength.mq4 |
//|                                                             Jens |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Jens"
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict
#include "../../Include/MyInclude/JensUtils.mqh";
extern int myMagic = 20180118;

extern double risk = 2.0;
extern int tracelevel = 2;

extern int strengthPeriod1 = 52;
extern ENUM_TIMEFRAMES entryTimeFrame1 = PERIOD_W1;
extern ENUM_TIMEFRAMES exitTimeFrame1 = PERIOD_D1;
extern int initialStop1 = 1;
extern int trailingStop1 = 2;
extern double trailByAtrFactor = 4.0;
extern int trailByATRPeriod = 12;
extern double minStop1 = 0.0;
extern double minStop1InPercent = 35.0;
extern double maxStop1 = 0.0;
extern double maxStop1InPercent = 200.0;

static datetime lastTradeTime = NULL;
static int lotDigits = -1;
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
  double lotstep = MarketInfo(Symbol(),MODE_LOTSTEP);
   if (lotstep == 1.0)        lotDigits = 0;
   if (lotstep == 0.1)        lotDigits = 1;
   if (lotstep == 0.01)       lotDigits = 2;
   if (lotstep == 0.001)      lotDigits = 3;
   if (lotstep == 0.0001)     lotDigits = 4;
   if (lotDigits == -1)       return(INIT_FAILED);   
//---
   
   
   PrintFormat("initialized with lotDigits=%i",lotDigits);
   
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
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
//---
   if (Time[0] == lastTradeTime) {
      return;
   }
   lastTradeTime = Time[0];
   
   if (trailByAtrFactor > 0.0) {
      trailByATR(myMagic,trailByATRPeriod, PERIOD_CURRENT, trailByAtrFactor);
   } else {
      trailWithLastXCandle(myMagic,trailingStop1,exitTimeFrame1);
   }
   
   //long 
   int highest = iHighest(Symbol(),entryTimeFrame1,MODE_HIGH,strengthPeriod1,0);
   int lowest = iLowest(Symbol(),exitTimeFrame1,MODE_LOW,initialStop1,0);
   
   double high1 = iHigh(Symbol(),entryTimeFrame1,highest);
   double stop1 = iLow(Symbol(),exitTimeFrame1, lowest);
   
   Comment("LONG high1: ", high1, "   stop1: ",stop1 );
   
   
   //create new long
   if (currentRisk(myMagic)<=0) { //consider open risk?
        
      if (minStop1>0.0 && (high1-stop1)<minStop1) {
         if (tracelevel > 1) PrintFormat("stop %.2f smaller than minStop %.2f, adapting to %.2f", (high1-stop1),minStop1, (high1-minStop1));
         stop1=high1-minStop1;
      }        
      if (minStop1InPercent >0.0) {
         double minStop = high1 * (minStop1InPercent/100);
         if ( (high1-stop1) < minStop) {
            if (tracelevel > 1) PrintFormat("stop %.2f smaller than minStop %.2f (%.2f percent), adapting to %.2f", (high1-stop1),minStop, minStop1InPercent, (high1-minStop));
            stop1=high1 - minStop;
         }
      }
      if (maxStop1 > 0.0 && (high1-stop1)>maxStop1) {
         if (tracelevel > 1) PrintFormat("stop %.2f larger than maxStop %.2f, adapting to %.2f", (high1-stop1),maxStop1, (high1-maxStop1));
         stop1=high1-maxStop1;
      }
      if (maxStop1InPercent > 0.0) {
         double maxStop = (maxStop1InPercent/100) * high1;
         if ((high1-stop1)>maxStop) {
            if (tracelevel > 1) PrintFormat("stop %.2f larger than maxStop %.2f (%.2f percent), adapting to %.2f", (high1-stop1),maxStop, maxStop1InPercent, (high1-maxStop));
            stop1=high1-maxStop;
         }
      }
      
      if (tracelevel > 0) 
         PrintFormat("buying strength at high=%.2f with stop at %.2f, Ask=%.2f",high1,stop1, Ask);
      
      if ((Ask) > high1) {
         double lots = lotsByRisk((Ask-stop1),risk,lotDigits);
         if (tracelevel > 0) 
            PrintFormat("buying %.2f lots immediately at Ask=%.2f",lots,Ask);
         closeAllPendingLongOrders(myMagic);
         OrderSend(Symbol(),OP_BUY,lots,Ask,3,stop1,0,"Buy stregnth",myMagic,0,clrGreen);
      } else {
         double lots = lotsByRisk((high1-stop1),risk,lotDigits);
         if (tracelevel > 0) 
            PrintFormat("stop buying strength lots=%.2f at high=%.2f and stop=%.2f (current Ask=%.2f)",lots,high1, stop1, Ask);
         bool orderExists = false;
         for (int i=OrdersTotal();i>=0;i--) {
            OrderSelect(i,SELECT_BY_POS,MODE_TRADES);
            if (OrderMagicNumber() != myMagic) continue;
            if (OrderSymbol() != Symbol()) continue;
            if (OrderCloseTime()>0) continue;
            if (OrderType() != OP_BUYSTOP) continue;
            if (OrderOpenPrice() == high1) {
               orderExists = true;
            }
         }
         
         if (!orderExists) {
               closeAllPendingLongOrders(myMagic);
               OrderSend(Symbol(),OP_BUYSTOP,lots,high1,5.0,stop1,0,"Buy strength",myMagic,0,clrGreen);
         }         
      }
   }
   
   //short
   int short_highest = iHighest(Symbol(),entryTimeFrame1,MODE_HIGH,strengthPeriod1,0);
   int short_lowest = iLowest(Symbol(),exitTimeFrame1,MODE_LOW,initialStop1,0);
   
   double short_low1 = iLow(Symbol(),exitTimeFrame1, short_lowest);
   double short_stop1 = iHigh(Symbol(),entryTimeFrame1,short_highest);
   
   Comment("SHOT low1: ", short_low1, "   stop1: ",short_stop1 );
   
   
   //create new short
   if (currentRisk(myMagic)<=0) { 
        
      if (minStop1>0.0 && (stop1-short_low1)<minStop1) {
         if (tracelevel > 1) PrintFormat("stop %.2f smaller than minStop %.2f, adapting to %.2f", (stop1-short_low1),minStop1, (short_low1+minStop1));
         stop1=short_low1+minStop1;
      }        
      if (minStop1InPercent >0.0) {
         double minStop = short_low1 * (minStop1InPercent/100);
         if ( (stop1-short_low1) < minStop) {
            if (tracelevel > 1) PrintFormat("stop %.2f smaller than minStop %.2f (%.2f percent), adapting to %.2f", (high1-stop1),minStop, minStop1InPercent, (short_low1+minStop));
            stop1=high1 - minStop;
         }
      }
      if (maxStop1 > 0.0 && (stop1-short_low1)>maxStop1) {
         if (tracelevel > 1) PrintFormat("stop %.2f larger than maxStop %.2f, adapting to %.2f", (high1-stop1),maxStop1, (short_low1+maxStop1));
         stop1=short_low1+maxStop1;
      }
      if (maxStop1InPercent > 0.0) {
         double maxStop = (maxStop1InPercent/100) * short_low1;
         if ((stop1-short_low1)>maxStop) {
            if (tracelevel > 1) PrintFormat("stop %.2f larger than maxStop %.2f (%.2f percent), adapting to %.2f", (high1-stop1),maxStop, maxStop1InPercent, (short_low1+maxStop));
            stop1=short_low1+maxStop;
         }
      }
      
      if (tracelevel > 0) 
         PrintFormat("selling weakness at low=%.2f with stop at %.2f, Bid=%.2f",short_low1,stop1, Bid);
      
      if ((Bid) < short_low1) {
         double lots = lotsByRisk((stop1-Bid),risk,lotDigits);
         if (tracelevel > 0) 
            PrintFormat("selling %.2f lots immediately at Bid=%.2f",lots,Bid);
         closeAllPendingShortOrders(myMagic);
         OrderSend(Symbol(),OP_SELL,lots,Bid,3,stop1,0,"Sell weakness",myMagic,0,clrGreen);
      } else {
         double lots = lotsByRisk((stop1-short_low1),risk,lotDigits);
         if (tracelevel > 0) 
            PrintFormat("stop selling weakness lots=%.2f at low=%.2f and stop=%.2f (current Bid=%.2f)",lots,short_low1, stop1, Bid);
         bool orderExists = false;
         for (int i=OrdersTotal();i>=0;i--) {
            OrderSelect(i,SELECT_BY_POS,MODE_TRADES);
            if (OrderMagicNumber() != myMagic) continue;
            if (OrderSymbol() != Symbol()) continue;
            if (OrderCloseTime()>0) continue;
            if (OrderType() != OP_SELLSTOP) continue;
            if (OrderOpenPrice() == short_low1) {
               orderExists = true;
            }
         }
         
         if (!orderExists) {
               closeAllPendingShortOrders(myMagic);
               OrderSend(Symbol(),OP_SELLSTOP,lots,short_low1,5.0,stop1,0,"Sell weakness",myMagic,0,clrGreen);
         }         
      }
   }

   
   
  }
//+------------------------------------------------------------------+
