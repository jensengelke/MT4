//+------------------------------------------------------------------+
//|                                                      system7.mq4 |
//|                                                    einfacher SMA |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "RangePingPong"
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
extern double usePercentOfRange = 90.0;
extern int orderExpiryInMin = 900;
extern double minBuffer = 5.0;
extern double minRange = 15.0;

datetime lastTradeTime = NULL;
int longTicket = 0;
int shortTicket = 0;

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
   
   if(lastTradeTime == Time[0]) {
      return;
   } else {
      lastTradeTime = Time[0];
   }
   
   double lowestLow = Low[iLowest(NULL,PERIOD_CURRENT,MODE_LOW,rangePeriod,0)];
   double highestHigh = High[iHighest(NULL,PERIOD_CURRENT,MODE_HIGH,rangePeriod,0)];
   
     
   if (0==OrdersTotal() && (highestHigh-lowestLow)<=range && minRange<(highestHigh-lowestLow)) {
      double buffer = (1-usePercentOfRange/100)*(highestHigh - lowestLow); 
      if (buffer<minBuffer) { buffer = minBuffer;}
      PrintFormat("highestHigh=%.2f, lowestLow=%.2f, rangePercent=%.0f, buffer=%.2f", highestHigh,lowestLow,usePercentOfRange,buffer);
      if (Ask > lowestLow + buffer+3.0) {
         openLongPosition(lots(baseLots, accountSize), lowestLow+buffer,lowestLow, highestHigh - buffer) ;
      }
      
      if (Bid < highestHigh - buffer) {
         openShortPosition(lots(baseLots, accountSize), highestHigh - buffer,highestHigh, lowestLow + buffer) ;
      }
   } else {
      for (int i=OrdersTotal(); i>=0;i--){
         OrderSelect(i,SELECT_BY_POS,MODE_TRADES);
         
         if (OrderMagicNumber() != myMagic) {continue;}
         if (OrderSymbol() != Symbol()) {continue;}
         if (OrderType()==OP_BUY) {
            if (Bid > (lowestLow + (highestHigh-lowestLow)/2) && OrderStopLoss()!=OrderOpenPrice()+(Ask-Bid)) {
               OrderModify(OrderTicket(),0,OrderOpenPrice()+(Ask-Bid),0,0,NULL);
            }
         } else if(OrderType() == OP_SELL) {
            if (Ask < (highestHigh - (highestHigh-lowestLow)/2) && OrderStopLoss()!=OrderOpenPrice()-(Ask-Bid)) {
               OrderModify(OrderTicket(),0,OrderOpenPrice()-(Ask-Bid),0,0,NULL);
            }
         
         }
      }
   }       
}
//+------------------------------------------------------------------+

int openLongPosition(double lots, double price, double stopLoss, double takeProfit) {
   RefreshRates();
   PrintFormat("buylimit: Ask=%.2f,price=%.2f, stop=%.2f,tp=%.2f",Ask,price,stopLoss,takeProfit);
   int ticket = OrderSend(NULL,OP_BUYLIMIT,lots,price,3,stopLoss,takeProfit,NULL,myMagic,TimeCurrent()+(orderExpiryInMin),clrGreen);     
   if (-1 == ticket) {
      Print("buystop last error: " + GetLastError());   
   } else {
     // Print("ticket:" + ticket);
   }
   
   return ticket;
}

int openShortPosition(double lots, double price, double stopLoss, double takeProfit) {
   PrintFormat("SellLimit: Bid=%.2f,price=%.2f, stop=%.2f,tp=%.2f",Bid,price, stopLoss,takeProfit);
   int ticket = OrderSend(NULL,OP_SELLLIMIT,lots,price,3,stopLoss,takeProfit,NULL,myMagic,TimeCurrent()+(orderExpiryInMin),clrRed);
   if (-1 == ticket) {
      Print("sellstop last error: " + GetLastError());   
   } else {
      //Print("ticket:" + ticket);
   }
   
   return ticket;
}