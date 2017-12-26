//+------------------------------------------------------------------+
//|                                                      system6.mq4 |
//|                          Egal wie's kommt, es kommt uns entgegen |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Egal wie's kommt, es kommt uns entgegen"
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

#include "../Include/JensUtils.mqh";

extern int startHour = 8;
extern int startMinute = 0;
extern int endHour = 21;
extern int endMinute = 58;
extern int myMagic = 20161119;
extern double baseLots = 0.2;
extern double accountSize = 1000.0;
extern double fixedTakeProfit = 0.0;
extern double initialStop = 0.0;
extern double trailInProfit = 10.0;
extern double buffer = 5.0;
extern int orderExpiryInMin = 900;
extern double stopAufEinstandBei = 5.0;

int longTicket = 0;
int shortTicket = 0;

string screenString = "StatusWindow";


//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
   if ( (initialStop==0.0 && trailInProfit==0.0) ||
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
   
   if (0==OrdersTotal()) {
      longTicket = openLongPosition(lots(baseLots, accountSize),Ask+buffer,initialStop,fixedTakeProfit);
      shortTicket = openShortPosition(lots(baseLots, accountSize),Bid-buffer,initialStop,fixedTakeProfit);
   }
   
   // trail order open limit and stop loss
   if (0<OrdersTotal() && (trailInProfit>0 || stopAufEinstandBei>0)) {
   
      double stopForShort = Bid + trailInProfit;
      double stopForLong = Ask - trailInProfit;
      double spread = Ask - Bid;
      
      for (int i=OrdersTotal(); i>=0;i--){
         OrderSelect(i,SELECT_BY_POS,MODE_TRADES);
         
         if (OrderMagicNumber() != myMagic) {continue;}
         if (OrderSymbol() != Symbol()) {continue;}
         if (OrderType()==OP_BUY) {
            //PrintFormat("BuyOrder is open, closing Sell Order: %i", shortTicket);
            closeOrder(shortTicket);
            if (trailInProfit>0 && OrderStopLoss()<stopForLong && OrderOpenPrice()<stopForLong) {
               PrintFormat("trailing long order: Bid=%.2f,Ask=%.2f,stopForLong=%.2f",Bid,Ask,stopForLong);
               if (!OrderModify(OrderTicket(),0,stopForLong,OrderTakeProfit(),0,clrGreen)){
                        PrintFormat("last error:%i ",GetLastError());                     
               }
            } else if (stopAufEinstandBei>0 && (OrderOpenPrice() + stopAufEinstandBei) <= Bid && (OrderStopLoss() <(OrderOpenPrice() + spread) )) {
               
               PrintFormat("Stop auf Einstand: OrderOpenPrice=%.2f, spread = %.2f, stop=%.2f, Bid=%.2f",OrderOpenPrice(),spread, (OrderOpenPrice()+spread),Bid);
               if (!OrderModify(OrderTicket(),0,(OrderOpenPrice() + spread),OrderTakeProfit(),0,clrGreen)){
                       PrintFormat("last error:%i ",GetLastError());                     
               }
            }
         }
         
         if (OrderType()==OP_SELL) {
            //PrintFormat("BuyOrder is open, closing Sell Order: %i", longTicket);
            closeOrder(longTicket);
            if (trailInProfit>0 && OrderStopLoss()>stopForShort && OrderOpenPrice()>stopForShort) {
               PrintFormat("trailing short order: Bid=%.2f,Ask=%.2f,stopForShort=%.2f",Bid,Ask,stopForShort);
               if (!OrderModify(OrderTicket(),0,stopForShort,OrderTakeProfit(),0,clrGreen)){
                        PrintFormat("last error:%i ",GetLastError());                     
               }
            }  else if (stopAufEinstandBei>0 && (OrderOpenPrice() - stopAufEinstandBei) >= Ask && (OrderStopLoss() > (OrderOpenPrice() - spread) )) {
               
               PrintFormat("Stop auf Einstand: OrderOpenPrice=%.2f, spread = %.2f, stop=%.2f, Ask=%.2f",OrderOpenPrice(),spread, (OrderOpenPrice()-spread),Ask);
               if (!OrderModify(OrderTicket(),0,(OrderOpenPrice() - spread),OrderTakeProfit(),0,clrGreen)){
                       PrintFormat("last error:%i ",GetLastError());                     
               }
            }
         }
      }
      
   }
   
  }
//+------------------------------------------------------------------+

int  openLongPosition(double lots, double price, double stopLoss, double takeProfit) {
   RefreshRates();
   double stop = 0;
   double tp = 0;
   int ticket = 0;
   
   if (Ask >= price) {
      if (stopLoss != 0) {
         stop = Ask - stopLoss;
      }
      if (takeProfit != 0) {
         tp = Ask +  takeProfit;
      }
      PrintFormat("buy: Ask=%.2f,stop=%.2f,tp=%.2f",Ask,stop,tp);
      ticket = OrderSend(NULL,OP_BUY,lots,Ask,2.0,stop,tp,NULL,myMagic,0,clrGreen);      
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
      
      PrintFormat("buystop: Ask=%.2f,price=%.2f, stop=%.2f,tp=%.2f",Ask,price,stop,tp);
      ticket = OrderSend(NULL,OP_BUYSTOP,lots,price,5,stop,tp,NULL,myMagic,TimeCurrent()+(orderExpiryInMin),clrGreen);     
      if (-1 == ticket) {
         Print("buystop last error: " + GetLastError());   
      } else {
        // Print("ticket:" + ticket);
      }
   }
   return ticket;
}

int openShortPosition(double lots, double price, double stopLoss, double takeProfit) {
   RefreshRates();
   double stop = 0;
   double tp = 0;
   int ticket=0;
   
   PrintFormat("openShortPos: Bid=%.2f, price=%.2f",Bid,price);
   
   if (Bid <= price) {
      if (stopLoss != 0) {
         stop = Bid + stopLoss;
      }
      if (takeProfit != 0) {
         tp = Bid - takeProfit;
      }
      PrintFormat("Sell: Bid=%.2f,stop=%.2f,stopLoss=%.2f,tp=%.2f",Bid,stop,stopLoss,tp);
      ticket = OrderSend(NULL,OP_SELL,lots,Bid,2.0,stop,tp,NULL,myMagic,0,clrGreen);      
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
      PrintFormat("SellStop: Bid=%.2f,price=%.2f, stop=%.2f,tp=%.2f",Bid,price, stop,tp);
      ticket = OrderSend(NULL,OP_SELLSTOP,lots,price,2,stop,tp,NULL,myMagic,TimeCurrent()+(orderExpiryInMin),clrRed);
       if (-1 == ticket) {
         Print("sellstop last error: " + GetLastError());   
      } else {
         //Print("ticket:" + ticket);
      }
   }
   return ticket;
}

void closeOrder(int ticket) {
   if (0==ticket) return;
   
   int currentTicket = OrderTicket();
   OrderSelect(ticket,SELECT_BY_TICKET,MODE_TRADES); 
   if (OrderType() == OP_BUYSTOP) {
      OrderDelete(ticket,clrWhite);
      longTicket = 0;
   } else if (OrderType() == OP_SELLSTOP) {
      shortTicket = 0;
      OrderDelete(ticket,clrWhite);
   }   
   OrderSelect(currentTicket, SELECT_BY_TICKET);
}
