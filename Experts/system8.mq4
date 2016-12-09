//+------------------------------------------------------------------+
//|                                                      system8.mq4 |
//|                                      ein bisschen was geht immer |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "ein bisschen was geht immer"
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

#include "../Include/JensUtils.mqh";

extern int startHour = 8;
extern int startMinute = 0;
extern int endHour = 21;
extern int endMinute = 58;
extern int myMagic = 20161124;
extern double baseLots = 1.0;
extern double accountSize = 1000.0;
extern double range = 30.0;
extern int rangePeriod = 60;
extern double minRange = 10;
extern double stop = 5.0;
extern double tp = 2.0;
extern double distance = 5.0;
extern double maxOrders = 4;
extern double stopAufEinstandBei = 10.0;

datetime lastTradeTime = NULL;
int longTicket = 0;
int shortTicket = 0;

string screenString = "StatusWindow";
string screenRect = "Range";

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
   
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
   
   if (stopAufEinstandBei>0 && OrdersTotal()>0) {
   
      double spread = Ask - Bid;
      
      for (int i=OrdersTotal();i>=0;i--) {
         OrderSelect(i,SELECT_BY_POS,MODE_TRADES);         
         if (OrderMagicNumber() != myMagic) {continue;}
         if (OrderSymbol() != Symbol()) {continue;}
         if (OrderType()==OP_BUY) {
            if ((OrderOpenPrice() + stopAufEinstandBei) <= Bid && (OrderStopLoss() <(OrderOpenPrice() + spread) )) {
               if (!OrderModify(OrderTicket(),0,(OrderOpenPrice() + spread),OrderTakeProfit(),0,clrGreen)){
                       PrintFormat("last error:%i ",GetLastError());                     
               }
            }
         }
         if (OrderType()==OP_SELL) {
            if ((OrderOpenPrice() - stopAufEinstandBei) >= Ask && (OrderStopLoss() > (OrderOpenPrice() - spread) )) {
               
               PrintFormat("Stop auf Einstand: OrderOpenPrice=%.2f, spread = %.2f, stop=%.2f, Ask=%.2f",OrderOpenPrice(),spread, (OrderOpenPrice()-spread),Ask);
               if (!OrderModify(OrderTicket(),0,(OrderOpenPrice() - spread),OrderTakeProfit(),0,clrGreen)){
                       PrintFormat("last error:%i ",GetLastError());                     
               }
            }
         }
      }
   }
   
   if(lastTradeTime == Time[0]) {
     return;
   } else {
      lastTradeTime = Time[0];
   }
   
   double lowestLow = Low[iLowest(NULL,PERIOD_CURRENT,MODE_LOW,rangePeriod,0)];
   double highestHigh = High[iHighest(NULL,PERIOD_CURRENT,MODE_HIGH,rangePeriod,0)];
   double spread = Ask - Bid;
   
   string status = StringFormat("actual range=%.2f (target=%.2f)", (highestHigh-lowestLow),range); 
   
   ObjectDelete(screenString);
   ObjectDelete(screenRect);
   ObjectCreate(screenString, OBJ_LABEL, 0, 0, 0);
   ObjectSetText(screenString,status, 8, "Arial Bold", clrRed);
   
   ObjectSet(screenString, OBJPROP_CORNER, 3);
   ObjectSet(screenString, OBJPROP_XDISTANCE, 10);
   ObjectSet(screenString, OBJPROP_YDISTANCE, 10); 
   
   ObjectCreate(screenRect, OBJ_RECTANGLE, 0,TimeCurrent()-60*rangePeriod*Period(),highestHigh,TimeCurrent(),lowestLow);
   ObjectSet(screenRect, OBJPROP_BACK, true);
   ObjectSet(screenRect, OBJPROP_COLOR, clrBlue);
   ObjectSet(screenRect, OBJPROP_STYLE, STYLE_SOLID);
   
     
   if (OrdersTotal()<maxOrders && (highestHigh-lowestLow)<=range && minRange<(highestHigh-lowestLow)) {
      if (countOpenPositions(myMagic,OP_BUY)<maxOrders/2 && Ask < lowestLow+(range/5)) {
         double stopLoss=Ask-spread-stop;
         if (stopLoss > lowestLow){ stop = lowestLow; }
         openLongPosition(lots(baseLots, accountSize), Ask, stopLoss, Ask+tp+spread) ;
      }
      if (countOpenPositions(myMagic,OP_SELL)<maxOrders/2 && Bid > (highestHigh-range/5) ) {
         double stopLoss=Bid+spread+stop;
         if (stopLoss < highestHigh){ stopLoss = highestHigh; }
         openShortPosition(lots(baseLots, accountSize), Bid, stopLoss, Bid-spread-tp) ;
      }
   }   
  }
//+------------------------------------------------------------------+
int openLongPosition(double lots, double price, double stopLoss, double takeProfit) {
   RefreshRates();
   
   double orderLots = NormalizeDouble(lots,1);
   double orderPrice = NormalizeDouble(price,Digits);
   double orderStop = NormalizeDouble(stopLoss,Digits);
   double orderProfit = NormalizeDouble(takeProfit,Digits);
   
  // PrintFormat("buystop: Ask=%.2f,lots=%.1f, price=%.2f,stop=%.2f,tp=%.2f",Ask,orderLots, orderPrice,orderStop, orderProfit);   
   
   int ticket = OrderSend(NULL,OP_BUY,orderLots,orderPrice,3, orderStop,orderProfit,NULL,myMagic,0,clrGreen);     
   if (-1 == ticket) {
      Print("buy last error: " + GetLastError());   
   } else {
     // Print("ticket:" + ticket);
   }
   
   return ticket;
}

int openShortPosition(double lots, double price, double stopLoss, double takeProfit) {
   PrintFormat("sellstop: Bid=%.2f,price=%.2f,stop=%.2f,tp=%.2f",Bid,price,stopLoss,takeProfit);
   int ticket = OrderSend(NULL,OP_SELL,lots,price, 3,stopLoss,takeProfit,NULL,myMagic,0,clrRed);
   if (-1 == ticket) {
      Print("sell last error: " + GetLastError());   
   } else {
      //Print("ticket:" + ticket);
   }
   
   return ticket;
}