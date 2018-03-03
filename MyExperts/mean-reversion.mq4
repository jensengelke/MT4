//+------------------------------------------------------------------+
//|                                               mean-reversion.mq4 |
//|                                                             Jens |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Jens"
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict
#include "../../Include/MyInclude/JensUtils.mqh";
extern int myMagic = 20180225;

extern int tracelevel = 2;
extern int bollingerPeriod = 20;
extern double bollingerDeviations = 1.5;
extern double immediateBuffer = 0.001;
extern double momentumDistance = 0.15;
extern int extremPeriod = 48;
extern int exitMode = 1;
extern double minStopDistance = 0.001;


static datetime lastTradeTime = NULL;
static int lotDigits = 5;
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  { 
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
   double bollingerUpper = NormalizeDouble(iBands(Symbol(),PERIOD_CURRENT,20,bollingerDeviations,0,PRICE_CLOSE,MODE_UPPER,1),5);
   double bollingerLower = NormalizeDouble(iBands(Symbol(),PERIOD_CURRENT,20,bollingerDeviations,0,PRICE_CLOSE,MODE_LOWER,1),5);
   
   if (exitMode == 2) {
      if (Bid > bollingerUpper) closeLongPositions(myMagic);
      if (Ask < bollingerLower) closeLongPositions(myMagic);
   }
   
   if (Time[0] ==lastTradeTime) return;
   lastTradeTime = Time[0];   
   
   
   double bollinger = NormalizeDouble(iBands(Symbol(),PERIOD_CURRENT,20,bollingerDeviations,0,PRICE_CLOSE,MODE_MAIN,0),5);
   
      
   if (exitMode == 1) {
      trail(myMagic,bollinger,bollinger,true);
      PrintFormat("trailing %5f at Bid=%5f", bollinger,Bid);
   } else {
      PrintFormat("exitmode: %i", exitMode);
   }
   
   
   
   //Momentum filter
   double currentMom = MathAbs(iMomentum(Symbol(),PERIOD_CURRENT,50,PRICE_CLOSE,0)-100);
   if (tracelevel > 1) {
      PrintFormat("momentum Distance %5f", currentMom);
   }
   if (momentumDistance > currentMom) {
      closeAllPendingOrders(myMagic);
      return;
   }
   double periodHigh = NormalizeDouble(iHigh(Symbol(),PERIOD_CURRENT, iHighest(Symbol(),PERIOD_CURRENT,MODE_HIGH, extremPeriod,1)),5);
   double periodLow = NormalizeDouble(iLow(Symbol(),PERIOD_CURRENT, iLowest(Symbol(),PERIOD_CURRENT,MODE_LOW, extremPeriod,1)),5);
   
   
   
   if (countOpenPositions(myMagic)<2) {
      double lots = 0.05;
      double stopShort = periodHigh;
      if (Ask > periodHigh - minStopDistance) {
         stopShort = periodHigh + 1.5*iATR(Symbol(),PERIOD_CURRENT,24,0);
      }
      
      double stopLong = periodLow;
      if (Bid > periodLow + minStopDistance) {
         stopLong = periodLow + 1.5*iATR(Symbol(),PERIOD_CURRENT,24,0);
      }
      
      stopShort = NormalizeDouble(stopShort,5);
      stopLong = NormalizeDouble(stopLong,5);
     
      if (bollingerUpper > Bid - immediateBuffer) { //stopsell               
         if (countOpenPendingShortOrders(myMagic)==0){ // new order
            sellLimit(lots,bollingerUpper,stopShort,bollingerLower);
         } else {
            updateSelllimt(bollingerUpper,stopShort,bollingerLower);
         }
      } else { //immediately
         closeAllPendingShortOrders(myMagic);
         sellImmediately(lots,stopShort,bollingerLower);
      }
      //TODO: BUYSIDE
      if (bollingerLower < Ask + immediateBuffer) {
         if (countOpenPendingLongOrders(myMagic)==0){ // new order
            buyLimit(lots,bollingerLower,stopLong,bollingerUpper);
         } else {
            updateBuylimit(bollingerLower,stopLong, bollingerUpper);
         }
      } else {
         closeAllPendingShortOrders(myMagic);
         buyImmediately(lots,stopLong,bollingerUpper);
      } 
  }
}
//+------------------------------------------------------------------+


void buyImmediately(double lots, double stop, double profit) {
   PrintFormat("BUY Ask=%5f, stop=%5f, tp=%5f",Ask,stop,profit);
   OrderSend(Symbol(),OP_BUY,lots,Ask,5,stop,profit,NULL,myMagic,0,clrGreen);
}

void sellImmediately(double lots, double stop, double profit) {
  PrintFormat("Sell Bid=%5f, stop=%5f, tp=%5f",Bid,stop,profit);
  OrderSend(Symbol(),OP_SELL,lots,Bid,5,stop,profit,NULL,myMagic,0,clrRed);
}

void sellLimit(double lots, double price, double stop, double profit) {
   PrintFormat("SELLLIMT Bid=%5f, sellimit=%5f, stop=%5f, tp=%5f",Bid,price,stop, profit);
   OrderSend(Symbol(),OP_SELLLIMIT,lots,price,5,stop,profit,NULL,myMagic,0,clrRed);
}

void buyLimit(double lots, double price, double stop, double profit) {
   PrintFormat("BUYLIMIT Ask=%5f, buyimit=%5f, stop=%5f, tp=%5f",Ask,price,stop, profit);
   OrderSend(Symbol(),OP_BUYLIMIT,lots,price,5,stop,profit,NULL,myMagic,0,clrRed);
}

void updateSelllimt(double price,double stop,double profit) {
   for (int i=OrdersTotal();i>=0;i--) {
      OrderSelect(i,SELECT_BY_POS,MODE_TRADES);
      if (OrderMagicNumber() != myMagic) continue;
      if (OrderSymbol() != Symbol()) continue;
      if (OrderType() == OP_SELLLIMIT) {
         bool needToModify = (OrderStopLoss() == stop);
         needToModify = needToModify && (OrderProfit() == profit);
         needToModify = needToModify && (OrderOpenPrice() == price);
         
         if (needToModify) {
            OrderModify(OrderTicket(),price,stop,profit,0,clrRed);
         }
      }
  }
}

void updateBuylimit(double price,double stop,double profit) {
   for (int i=OrdersTotal();i>=0;i--) {
      OrderSelect(i,SELECT_BY_POS,MODE_TRADES);
      if (OrderMagicNumber() != myMagic) continue;
      if (OrderSymbol() != Symbol()) continue;
      if (OrderType() == OP_BUYLIMIT) {
         bool needToModify = (OrderStopLoss() == stop);
         needToModify = needToModify && (OrderProfit() == profit);
         needToModify = needToModify && (OrderOpenPrice() == price);
         
         if (needToModify) {
            OrderModify(OrderTicket(),price,stop,profit,0,clrGreen);
         }
      }
  }
}