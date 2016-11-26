//+------------------------------------------------------------------+
//|                                                  JensUtils.h.mqh |
//|                                                       mehr davon |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "mehr davon"
#property link      "https://www.mql5.com"
#property strict

double currentRisk(int myMagic) {
   double currentRisk = 0.0;
   for (int i=OrdersTotal();i>=0;i--) {
      OrderSelect(i,SELECT_BY_POS,MODE_TRADES);
      if (OrderMagicNumber() != myMagic) continue;
      if (OrderSymbol() != Symbol()) continue;
      if (OrderCloseTime()>0) continue;
     
      if (OrderType() == OP_BUY){
         currentRisk+=OrderLots() * (OrderOpenPrice() - OrderStopLoss());
      }
      if (OrderType() == OP_SELL) {
        currentRisk+=OrderLots() * (OrderStopLoss()- OrderOpenPrice());
      }
   }
   return currentRisk;
}


double lots(double baseLots, double accountSize) {
   double lots = baseLots;
   double equityPercentage = AccountEquity()/AccountBalance();
   int equityTimes = MathFloor( (AccountEquity()/accountSize) * equityPercentage );  // how many time is present equity times BaseEquity
   if(equityTimes >= 1) {
         lots = baseLots*equityTimes;                 // total new open Lots
   }         
   if (lots > MarketInfo(Symbol(), MODE_MAXLOT)) {
      lots = MarketInfo(Symbol(), MODE_MAXLOT);
   }
   return lots;
}

void closeAllPendingOrders(int myMagic) {
 for (int i=OrdersTotal();i>=0;i--) {
      OrderSelect(i,SELECT_BY_POS,MODE_TRADES);
      if (OrderMagicNumber() != myMagic) continue;
      if (OrderSymbol() != Symbol()) continue;
      if (OrderType() == OP_BUYSTOP ||
         OrderType() == OP_SELLSTOP ||
         OrderType() == OP_SELLLIMIT ||
         OrderType() == OP_BUYLIMIT) {
         OrderDelete(OrderTicket(),clrWhite);
      }
   }
}

int countOpenPendingOrders(int myMagic) {
   int openPendingOrders = 0;
   for (int i=OrdersTotal();i>=0;i--) {
      OrderSelect(i,SELECT_BY_POS,MODE_TRADES);
      if (OrderMagicNumber() != myMagic) continue;
      if (OrderSymbol() != Symbol()) continue;
      if (OrderType() == OP_BUYSTOP ||
         OrderType() == OP_SELLSTOP ||
         OrderType() == OP_SELLLIMIT ||
         OrderType() == OP_BUYLIMIT) {
         openPendingOrders++;
      }
   }
   return openPendingOrders;
}

int countOpenPositions(int myMagic) {
   int openPositons = 0;
   for (int i=OrdersTotal();i>=0;i--) {
      OrderSelect(i,SELECT_BY_POS,MODE_TRADES);
      if (OrderMagicNumber() != myMagic) continue;
      if (OrderSymbol() != Symbol()) continue;
      if (OrderType() == OP_BUY ||
         OrderType() == OP_SELL) {
         openPositons++;
      }
   }
   return openPositons;
}

int countOpenPositions(int myMagic, int mode) {
   int openPositons = 0;
   for (int i=OrdersTotal();i>=0;i--) {
      OrderSelect(i,SELECT_BY_POS,MODE_TRADES);
      if (OrderMagicNumber() != myMagic) continue;
      if (OrderSymbol() != Symbol()) continue;
      if (OrderType() == mode) {
         openPositons++;
      }
   }
   return openPositons;
}


void closeAllOpenOrders(int myMagic) {
 RefreshRates();
 for (int i=OrdersTotal();i>=0;i--) {
      OrderSelect(i,SELECT_BY_POS,MODE_TRADES);
      if (OrderMagicNumber() != myMagic) continue;
      if (OrderSymbol() != Symbol()) continue;
      if (OrderType() == OP_BUY) {
         OrderClose(OrderTicket(),OrderLots(),Bid,2,clrWhite);
      }
      
      if (OrderType() == OP_SELL) {
         OrderClose(OrderTicket(),OrderLots(),Ask,2,clrWhite);
      }
   }
}
