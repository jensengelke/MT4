//+------------------------------------------------------------------+
//|                                                     rsi_grid.mq4 |
//|                                                          DerJens |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "DerJens"
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

#include "../../Include/Arrays/ArrayInt.mqh";

input string label0 = "" ; //+--- admin ---+
input int myMagic = 20180819;
input int tracelevel = 2;
input string chartLabel = "RSI grid";

input string label1 = "" ; //+--- entry signal ---+
input int rsiPeriod = 12;
input double rsiLowThreshold = 25;
input double rsiHighThreshold = 85;

input string label2 = ""; //+--- money management ---+
input double lots = 0.01;
input double tpPoints = 400;
input double martingaleFactor = 3.0;
input double martingaleMinDistance = 100;

CArrayInt longTickets;
CArrayInt shortTickets;


static datetime lastTradeTime = NULL;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
   Comment(chartLabel);
   
   longTickets.Clear();
   shortTickets.Clear();
   for (int i=OrdersTotal(); i>=0; i--) {
      if (OrderSelect(i, SELECT_BY_POS) && OrderMagicNumber() == myMagic && OrderSymbol() == _Symbol) {
         if (OrderType() == OP_BUY) {
            longTickets.Add(OrderTicket());
         } else if ( OrderType() == OP_SELL) {
            shortTickets.Add(OrderTicket());
         }
      }
   }
   
   PrintFormat("Init: Point=%.5f",_Point);
   
   
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
//---
   if (Time[0] == lastTradeTime) return;
   
   lastTradeTime = Time[0];
   
   double rsi = iRSI(Symbol(),PERIOD_CURRENT,rsiPeriod,PRICE_CLOSE,0);
   double rsiPrev = iRSI(Symbol(),PERIOD_CURRENT,rsiPeriod,PRICE_CLOSE,1);
   
   if (rsiPrev > rsiHighThreshold && rsi < rsiHighThreshold) {
      //short signal
      int ticket = sell();
      if (ticket > -1) 
         shortTickets.Add(ticket);
      
   }
   
   if (rsiPrev < rsiLowThreshold && rsi > rsiLowThreshold) {
      //long signal
      int ticket = buy();
      if (ticket > -1) 
         longTickets.Add(ticket);
   }
   
  }
//+------------------------------------------------------------------+


int sell() {

   double entry = NormalizeDouble(Bid, _Digits);
   int ticket = -1;
   
   double currentSizeOfOpenPositions = 0.0;
   int currentCountOfOpenPositions = 0;
   
   double pointsToRecover = 0.0;
   double highestEntry = -1.0;
   
   for (int i=shortTickets.Total(); i>=0; i--) {
      if (OrderSelect(shortTickets.At(i),SELECT_BY_TICKET)) {
         if (OrderCloseTime()!=0) {
            shortTickets.Delete(i);
         } else {
            currentCountOfOpenPositions++;
            currentSizeOfOpenPositions+=OrderLots();
            pointsToRecover += ((entry-OrderOpenPrice())*(OrderLots()/lots))/_Point;
            if (tracelevel >= 2) {
               PrintFormat("SELL: thisEntry=%.5f, orderEntry=%.5f, orderSize=%.2f, lots=%.2f, pointsToRecover=%.5f",
                  entry,
                  OrderOpenPrice(),
                  OrderLots(),
                  lots,
                  pointsToRecover);
            }
         }
         if (highestEntry < 0 || highestEntry < OrderOpenPrice()) {
            highestEntry = OrderOpenPrice();
         }
      }
   }
   
   if (highestEntry > 0.0) {
      double martingaleDistance = (entry -highestEntry)/_Point;
      if ( martingaleDistance < martingaleMinDistance) {
         if (tracelevel>=1) {
            PrintFormat("SKIPPING SELL signal: current price is %.2f (less than martingaleMinDistance: %.2f) points away from highest entry", martingaleDistance, martingaleMinDistance);
         }
         return ticket;
      }
   }
   
   double size = lots;
   if (currentCountOfOpenPositions > 0) {
      size = MathPow(martingaleFactor,currentCountOfOpenPositions)*lots;
   }
   
   double totalSize = currentSizeOfOpenPositions + size;
   double totalTarget = pointsToRecover + (tpPoints*lots/size);
   double thisTpPoints = totalTarget * lots/totalSize; 
   double tp = entry - (thisTpPoints*_Point);
     
   //PrintFormat("SELL: size=%.5f, totalSize: %.5f, totalTarget = %.5f", size, totalSize, totalTarget);  
   ticket = OrderSend(Symbol(),OP_SELL,size,entry,1000,0,tp,"rsi-grid",myMagic,0,clrRed);
   if (ticket>0) {
      for (int i=shortTickets.Total(); i>=0; i--) {
         if (OrderSelect(shortTickets.At(i),SELECT_BY_TICKET)) {
            if (!OrderModify(OrderTicket(),0,0,tp,0,clrGreen)) {
               PrintFormat("ERROR!");
            }
         }
      }
   }
   return ticket;
}

int buy() {
   double entry = NormalizeDouble(Ask, _Digits);
   int ticket = -1;
   
   double currentSizeOfOpenPositions = 0.0;
   int currentCountOfOpenPositions = 0;
   double pointsToRecover = 0.0;
   double lowestEntry = -1.0;
   
   for (int i=longTickets.Total(); i>=0; i--) {
      if (OrderSelect(longTickets.At(i),SELECT_BY_TICKET)) {
         if (OrderCloseTime()!=0) {
            longTickets.Delete(i);
         } else {
            currentCountOfOpenPositions++;
            currentSizeOfOpenPositions+=OrderLots();
            pointsToRecover += ((OrderOpenPrice()-entry)*(OrderLots()/lots))/_Point;
            if (tracelevel >=2) {
               PrintFormat("BUY: thisEntry=%.5f, orderEntry=%.5f, orderSize=%.2f, lots=%.2f, pointsToRecover=%.5f",
                  entry,
                  OrderOpenPrice(),
                  OrderLots(),
                  lots,
                  pointsToRecover);
            }
               
            if (lowestEntry < 0 || lowestEntry > OrderOpenPrice()) {
            lowestEntry = OrderOpenPrice();
         }      
         }
      }
   }
   
   if (lowestEntry > 0.0) {
      double martingaleDistance = (lowestEntry - entry)/_Point;
      if ( martingaleDistance < martingaleMinDistance) {
         if (tracelevel>=1) {
            PrintFormat("SKIPPING BUY signal: current price is %.2f (less than martingaleMinDistance: %.2f) points away from highest entry", martingaleDistance, martingaleMinDistance);
         }
         return ticket;
      }
   }
      
   double size = lots;
   if (currentCountOfOpenPositions>0) {
      size = MathPow(martingaleFactor,currentCountOfOpenPositions)*lots;
   }
   
   double totalSize = currentSizeOfOpenPositions + size;
   double totalTarget = pointsToRecover + (tpPoints*lots/size);
   double thisTpPoints =totalTarget * lots/totalSize; 
   double tp = entry + (thisTpPoints*_Point);
   //PrintFormat("BUY size: %.5f, totalSize: %.5f, totalTarget = %.5f, thisTpPoints=%.2f, tp=%.5f", size, totalSize, totalTarget, thisTpPoints, tp);
   
   ticket = OrderSend(Symbol(),OP_BUY,size,entry,1000,0,tp,"rsi-grid",myMagic,0,clrGreen);
   
   if (ticket>0) {
      for (int i=longTickets.Total(); i>=0; i--) {
         if (OrderSelect(longTickets.At(i),SELECT_BY_TICKET)) {
            if (!OrderModify(OrderTicket(),0,0,tp,0,clrGreen)) {
               PrintFormat("ERROR!");
            }
         }
      }
   }
   
   
   return ticket;
}