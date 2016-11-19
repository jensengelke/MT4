//+------------------------------------------------------------------+
//|                                                      system5.mq4 |
//|                                                       mehr davon |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "mehr davon"
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

#include "../Include/JensUtils.mqh";

extern int startHour = 8;
extern int startMinute = 0;
extern int endHour = 21;
extern int endMinute = 58;
extern int myMagic = 20161028;
extern double baseLots = 0.2;
extern double accountSize = 1000.0;
extern double fixedTakeProfit = 0.0;
extern double initialStop = 0.0;
extern double trailInProfit = 10.0;
extern int extremeCandles = 60;
extern double buffer = 5.0;
extern int orderExpiryInMin = 3600;
static datetime lastTradeTime = NULL;
extern int maxPositions = 5;
extern int initialStopAtXCandleExtreme = 5;
extern int trailWithXCandleExtreme = 5;
extern double minCandleSize = 10.0;

string screenString = "StatusWindow";
string screenHighLine = "highLine";
string screenLowLine = "lowLine";

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
   if ( (fixedTakeProfit==0.0 && trailInProfit==0.0 && trailWithXCandleExtreme==0) ||
      (trailInProfit!=0 && trailWithXCandleExtreme !=0) ||
      (initialStop==0 && initialStopAtXCandleExtreme==0) ||
      (orderExpiryInMin < 900) ) {
      return (INIT_FAILED);
   }
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
  if(lastTradeTime == Time[0]) {
      //return;
   } else {
      lastTradeTime = Time[0];
   }
  
   double lowestLow = Low[iLowest(NULL,PERIOD_CURRENT,MODE_LOW,extremeCandles,0)];
   double highestHigh = High[iHighest(NULL,PERIOD_CURRENT,MODE_HIGH,extremeCandles,0)];
   int openPos = countOpenPositions(myMagic);
   int openPendingPos = countOpenPendingOrders(myMagic);
   double risk = currentRisk(myMagic);
   string status = StringFormat("spread=%.5f, currentRisk=%.2f, highest high=%.2f, lowest low=%.2f",(Bid-Ask),risk,highestHigh,lowestLow);   
      
   ObjectDelete(screenString);
   ObjectCreate(screenString, OBJ_LABEL, 0, 0, 0);
   if (risk <=0) {
      ObjectSetText(screenString,status, 8, "Arial Bold", clrGreen);
   } else {
     ObjectSetText(screenString,status, 8, "Arial Bold", clrRed);
   }
   ObjectSet(screenString, OBJPROP_CORNER, 3);
   ObjectSet(screenString, OBJPROP_XDISTANCE, 10);
   ObjectSet(screenString, OBJPROP_YDISTANCE, 10); 
 
    if (
      DayOfWeek()<1 || 
      DayOfWeek()>5 ||
      TimeHour(TimeLocal())<startHour || 
      TimeHour(TimeLocal())> endHour ||
      ( TimeHour(TimeLocal())== endHour &&  TimeMinute(TimeLocal())>=endMinute)) {
         closeAllPendingOrders(myMagic);
         closeAllOpenOrders(myMagic);
      return;
   }
   
   
   if (
          (0==openPendingPos && 0==openPos) ||
          ((openPos>0) && ((openPos+openPendingPos)<maxPositions) && (currentRisk(myMagic)<=0)) // open positions, but no risk
       ) {
      //open new positions?
      if (High[0] == highestHigh && (High[0]-Low[0]>minCandleSize)) {
          double stop = 0;
          
          if (initialStopAtXCandleExtreme>0) {
            stop = highestHigh + buffer - Low[iLowest(NULL,PERIOD_CURRENT,MODE_LOW,initialStopAtXCandleExtreme,0)];
          }
          if (0<initialStop && (0==stop || stop>initialStop)) {
             stop = initialStop;
         }
         openLongPosition(lots(baseLots, accountSize),highestHigh + buffer, stop , fixedTakeProfit);
      }   
      if (Low[0] <= lowestLow && (High[0]-Low[0]>minCandleSize)) {
         double stop = 0;
         if (initialStopAtXCandleExtreme>0) {
            stop = (High[iHighest(NULL,PERIOD_CURRENT,MODE_HIGH,initialStopAtXCandleExtreme,0)] - lowestLow - buffer);
         }
         if (0<initialStop && (0==stop || stop>initialStop)) {
            stop = initialStop;
         }
         openShortPosition(lots(baseLots, accountSize),lowestLow - buffer, stop, fixedTakeProfit);
      }
   }
   
   if (OrdersTotal()>0 && (trailInProfit > 0 || trailWithXCandleExtreme>0)) {
      RefreshRates();
      double stopForLong,stopForShort;
      
      if (trailInProfit > 0) {
         stopForLong = Bid - trailInProfit;
         stopForShort = Ask + trailInProfit;
      } else {
         stopForLong = Low[iLowest(NULL,PERIOD_CURRENT,MODE_LOW,trailWithXCandleExtreme,0)];
         //PrintFormat("checking stopForLong=%.2f and Bid=%.2f",stopForLong,Bid);
         if (stopForLong > Bid) {
            stopForLong = 0;
         }
         stopForShort = High[iHighest(NULL,PERIOD_CURRENT,MODE_HIGH,trailWithXCandleExtreme,0)];
         //PrintFormat("checking stopForShort=%.2f and Ask=%.2f",stopForShort,Ask);
         if (stopForShort < Ask) {
            stopForShort = 0;
         }
      }
      //PrintFormat("Ask=%.2f, stopForLong=%.2f, stopForShort=%.2f",stopForLong,stopForShort);
      bool updateRemainingOrders = false;
      for (int i=OrdersTotal();i>=0;i--) {
         OrderSelect(i,SELECT_BY_POS,MODE_TRADES);
         if (OrderMagicNumber() != myMagic) {continue;}
         if (OrderSymbol() != Symbol()) {continue;}
         if (OrderProfit() > 0) {
            if (OrderType() == OP_BUY && stopForLong > 0) {
               //PrintFormat("OrderStopLoss=%.2f, OrderOpenPrice=%.2f",OrderStopLoss(),OrderOpenPrice());
               if (updateRemainingOrders || (OrderStopLoss() < stopForLong && OrderOpenPrice()<stopForLong)) {
                 if (!OrderModify(OrderTicket(),0,stopForLong,OrderTakeProfit(),0,clrGreen)) {
                  PrintFormat("adapt stopForLong=%.2f, Bid=%.2f, minStopLevel=%.2f, last error:%i ",stopForLong, Bid, GetLastError());   
                 } else {
                  updateRemainingOrders = true;
                 }
               }
               continue;
            } 
            if (OrderType() == OP_SELL && stopForShort > 0) {
               if (updateRemainingOrders || (OrderStopLoss() > stopForShort && OrderOpenPrice()>stopForShort)) {
                  if (!OrderModify(OrderTicket(),0,stopForShort,OrderTakeProfit(),0,clrRed)){
                     PrintFormat("adapt stopForShort=%.2f, Ask=%.2f, minStopLevel=%.2f, last error:%i ",stopForShort, Ask, GetLastError());                     
                 } else {
                  updateRemainingOrders = true;
                 }
               }
            }
         }
     }
   }


  }
//+------------------------------------------------------------------+


void openLongPosition(double lots, double price, double stopLoss, double takeProfit) {
   RefreshRates();
   double stop = 0;
   double tp = 0;
   
   if (Ask >= price) {
      if (stopLoss != 0) {
         stop = Ask - stopLoss;
      }
      if (takeProfit != 0) {
         tp = Ask +  takeProfit;
      }
      PrintFormat("buy: Ask=%.2f,stop=%.2f,tp=%.2f",Ask,stop,tp);
      int ticket = OrderSend(NULL,OP_BUY,lots,Ask,2.0,stop,tp,NULL,myMagic,0,clrGreen);      
       if (-1 == ticket) {
            Print("OrderBuy last error: " + GetLastError());   
         } else {
            //Print("ticket:" + ticket);
         }  
   } else {
      if (stopLoss != 0) {
         stop = price - stopLoss;
      }
      if (takeProfit != 0) {
         tp = price +  takeProfit;
      }
      if (!pendingOrderAt(OP_BUYSTOP, price)) {
         PrintFormat("buystop: Ask=%.2f,price=%.2f, stop=%.2f,tp=%.2f",Ask,price,stop,tp);
         int ticket = OrderSend(NULL,OP_BUYSTOP,lots,price,5,stop,tp,NULL,myMagic,TimeCurrent()+(orderExpiryInMin),clrGreen);     
         if (-1 == ticket) {
            Print("buystop last error: " + GetLastError());   
         } else {
           // Print("ticket:" + ticket);
         }
      }
   }
}

void openShortPosition(double lots, double price, double stopLoss, double takeProfit) {
   RefreshRates();
   double stop = 0;
   double tp = 0;
   
   if (Bid <= price) {
      if (stopLoss != 0) {
         stop = Bid + stopLoss;
      }
      if (takeProfit != 0) {
         tp = Bid - takeProfit;
      }
      PrintFormat("Sell: Bid=%.2f,stop=%.2f,stopLoss=%.2f,tp=%.2f",Bid,stop,stopLoss,tp);
      int ticket = OrderSend(NULL,OP_SELL,lots,Bid,2.0,stop,tp,NULL,myMagic,0,clrGreen);      
      if (-1 == ticket) {
            Print("sell last error: " + GetLastError());   
         } else {
           // Print("ticket:" + ticket);
         }  
   } else {
      if (stopLoss != 0) {
         stop = price + stopLoss;
      }
      if (takeProfit != 0) {
         tp = price - takeProfit;
      }
      if (!pendingOrderAt(OP_SELLSTOP, price)) {
         PrintFormat("SellStop: Bid=%.2f,price=%.2f, stop=%.2f,tp=%.2f",Bid,price, stop,tp);
         int ticket = OrderSend(NULL,OP_SELLSTOP,lots,price,2,stop,tp,NULL,myMagic,TimeCurrent()+(orderExpiryInMin),clrRed);
          if (-1 == ticket) {
            Print("sellstop last error: " + GetLastError());   
         } else {
            //Print("ticket:" + ticket);
         }
      }
   }
   
}

bool pendingOrderAt(int orderType, double price) {
   bool exists = false;
   for (int i=OrdersTotal();i>=0;i--) {
         OrderSelect(i,SELECT_BY_POS,MODE_TRADES);
         if (OrderMagicNumber() != myMagic) {continue;}
         if (OrderSymbol() != Symbol()) {continue;}
         if (!OrderType()==orderType) {continue;}
         if (!OrderOpenPrice()==price) {continue;}
         exists = true;
         break;
     }
   return exists;
}
