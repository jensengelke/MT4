//+------------------------------------------------------------------+
//|                                                          ORB.mq4 |
//|                                                          DerJens |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "DerJens"
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

#include <Arrays/ArrayInt.mqh>

input string label0 = "" ; //+--- admin ---+
input int    myMagic = 1;
input int    tracelevel = 2;
input string chartLabel = "ORB";

input string label1 = "" ; //+--- entry signal ---+
input int    startHour = 8;
input int    startMinute = 0;
input int    lookBack = 8; // number of prior candles
input double minRange = 30.0; 
input double triggerDistance = 5.0;
input int    flatAfterHour = 22;
input double pyramideMinDistance = 50.0; //min distance for opening another position in the same direction, 0=disabled

input string label2 = ""; //+--- money management ---+
input double lots = 0.3;
input bool   stopAtRange = false;
input double stopInPercent = 2.0;
input double tpInPercent = 0.4;
input double trailInPercent = 0.2;
input bool   closeOverNight = true;
input bool   closeOverWeekend = true;


static datetime lastTradeTime = NULL;
static CArrayInt longTickets;
static CArrayInt shortTickets;



//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
Print("initializing");
   if (startHour > 23 || startHour < 0) return(INIT_PARAMETERS_INCORRECT);
   if (flatAfterHour <= startHour) return(INIT_PARAMETERS_INCORRECT);
   if (closeOverNight && closeOverWeekend) return (INIT_PARAMETERS_INCORRECT);
   if (stopInPercent > 0.0 && stopAtRange) return (INIT_PARAMETERS_INCORRECT);
   if (stopInPercent == 0.0 && !stopAtRange) return (INIT_PARAMETERS_INCORRECT);
   if (!closeOverNight && !closeOverWeekend && flatAfterHour != 22) return (INIT_PARAMETERS_INCORRECT);
   if (trailInPercent > tpInPercent) return (INIT_PARAMETERS_INCORRECT);
   
   longTickets.Clear();
   shortTickets.Clear();
   for (int i=OrdersTotal(); i>=0; i--) {
      if (OrderSelect(i, SELECT_BY_POS) && OrderMagicNumber() == myMagic) {
         if (StringCompare(OrderSymbol(), Symbol(),false)!=0) {
            PrintFormat("MagicNumber already in use!");          
            return INIT_FAILED;
         }
         if (OrderType() == OP_BUY) {
            longTickets.Add(OrderTicket());
         } else if ( OrderType() == OP_SELL) {
            shortTickets.Add(OrderTicket());
         }
      }
   }
   
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
   if (Time[0] == lastTradeTime) return;
   
   lastTradeTime = Time[0];
   PrintFormat("longtickets at the beginning: %i", longTickets.Total());
   
   double currentLots = NormalizeDouble(AccountBalance() / 600 * lots,1);
   
   //1. clean ticket arays - SL or TP events may have occured
   //trail, while accessing the arrays anyways
    for (int i=longTickets.Total(); i>=0;i--) {
         if (OrderSelect(longTickets.At(i),SELECT_BY_TICKET,MODE_TRADES)) {
            if (OrderCloseTime() != 0 && OrderType()==OP_BUY) {
               longTickets.Delete(i);
            } else if (OrderType() == OP_BUY) {
               double trailStop = NormalizeDouble( (100-trailInPercent)/100*Bid,Digits());
               if (OrderStopLoss() < trailStop) {
                  if (!OrderModify(OrderTicket(),0,trailStop,OrderTakeProfit(),0,clrGreen)) {
                     Print("ERROR 005");
                  }
               }
            }
         }
    }
    for (int i=shortTickets.Total(); i>=0;i--) {
         if (OrderSelect(shortTickets.At(i),SELECT_BY_TICKET,MODE_TRADES)) {
            if (OrderCloseTime() != 0 && OrderType()==OP_SELL) {
               shortTickets.Delete(i);
            } else if (OrderType() == OP_SELL) {
               double trailStop = NormalizeDouble( (100+trailInPercent)/100*Ask,Digits());
               if (OrderStopLoss() > trailStop) {
                  if (!OrderModify(OrderTicket(),0,trailStop,OrderTakeProfit(),0,clrGreen)) {
                     Print("ERROR 006");
                  } 
               }
            }
        }
    }
   
   PrintFormat("longtickets at #2: %i", longTickets.Total());
   //2. create new pending orders at trigger time     
   if (TimeHour(TimeCurrent()) == startHour && TimeMinute(TimeCurrent()) == startMinute) {
      double high = High[iHighest(_Symbol,PERIOD_CURRENT,MODE_HIGH,lookBack,0)];
      double low  = Low[iLowest(_Symbol,PERIOD_CURRENT,MODE_LOW,lookBack,0)];
      double range = high - low;
      if (tracelevel > 1) PrintFormat("range: %.5f (%.5f ... %.5f)", range,low,high);
      if (range > minRange) {
         if (longTickets.Total() == 0 || pyramideMinDistance > 0) {
            
            double buyTrigger = NormalizeDouble(high + triggerDistance,Digits());
            double buyStop = NormalizeDouble(buyTrigger*(100-stopInPercent)/100,Digits());
            if (stopAtRange) {
               buyStop = NormalizeDouble(low - triggerDistance, Digits());
            }
            double buyTarget = NormalizeDouble(buyTrigger * (100+tpInPercent)/100, Digits());
            
            if (tracelevel > 1) PrintFormat("longtickets=%i", longTickets.Total());
            if (longTickets.Total() > 0) {
               double highestEntry = 0.0;
               for (int i=longTickets.Total();i>=0;i--) {
                  if (OrderSelect(longTickets.At(i),SELECT_BY_TICKET,MODE_TRADES)) {
                     if (OrderOpenPrice() > highestEntry) highestEntry = OrderOpenPrice();
                  }
               }
               if ((buyTrigger - highestEntry) < pyramideMinDistance) buyTrigger = 0.0;
               if (tracelevel > 1) PrintFormat("highestEntry: %.2f, pyramide: %.2f, buyTrigger=%.2f",highestEntry,pyramideMinDistance,buyTrigger);
            }
            
            if (buyTrigger > 0.0) {
               if (tracelevel > 0) PrintFormat("Buy %.2f lots at %.5f with stop %.5f and target %.5f, Ask=%.5f)",lots,buyTrigger,buyStop,buyTarget,Ask);
               int longticket = OrderSend(Symbol(),OP_BUYSTOP,currentLots,buyTrigger,100,buyStop,buyTarget,"ORB",myMagic, 0,clrGreen);
               if (longticket == -1) {
                  PrintFormat("ERROR 007");
               } else {
                  longTickets.Add(longticket);
               }
            } else {
               if (tracelevel>=1) PrintFormat("  buystop, because it is not sufficiently higher than an existing open order");
            }
            
         }
         
         if (shortTickets.Total() == 0 || pyramideMinDistance > 0) {
            double sellTrigger = NormalizeDouble(low - triggerDistance,Digits());
            double sellStop = NormalizeDouble(sellTrigger*(100+stopInPercent)/100,Digits());
            if (stopAtRange) {
               sellStop = NormalizeDouble(high + triggerDistance, Digits());
            }
            double sellTarget = NormalizeDouble(sellTrigger * (100-tpInPercent)/100, Digits());
            
            if (shortTickets.Total() > 0) {
               double lowestEntry = 0.0;
               for (int i=shortTickets.Total();i>=0;i--) {
                  if (OrderSelect(shortTickets.At(i),SELECT_BY_TICKET,MODE_TRADES)) {
                     if (OrderOpenPrice() < lowestEntry || 0==lowestEntry) lowestEntry = OrderOpenPrice();
                  }
               }
               if ((lowestEntry - sellTrigger) < pyramideMinDistance) sellTrigger = 0.0;
            }
            
            if (sellTrigger > 0.0) {
               if (tracelevel > 0) PrintFormat("Sell %.2f lots at %.5f with stop %.5f and target %.5f, Bid=%.f",lots,sellTrigger,sellStop,sellTarget,Bid);         
               int shortticket = OrderSend(Symbol(),OP_SELLSTOP,currentLots,sellTrigger,100,sellStop,sellTarget,"ORB",myMagic, 0,clrRed);
               if (shortticket == -1) {
                  PrintFormat("ERROR 008");
               } else {
                  shortTickets.Add(shortticket);
               }
            } else {
               if (tracelevel>=1) PrintFormat("Skipping sellstop, because it is not sufficiently higher than an existing open order");
            }
         }        
      }
   } 
   
   
   PrintFormat("longtickets at #3: %i", longTickets.Total());
   //3. close open and pending orders in the evening (or over the weekend)
   if (TimeHour(TimeCurrent()) >= flatAfterHour && OrdersTotal() > 0) {
      
      PrintFormat("Cleaning in the evening");
      for (int i=longTickets.Total(); i>=0;i--) {
         if (OrderSelect(longTickets.At(i),SELECT_BY_TICKET,MODE_TRADES)) {
            if (OrderType() == OP_BUYSTOP) {
               if (!OrderDelete(OrderTicket())) {
                  PrintFormat("ERROR 001");
                  longTickets.Delete(i); //take profit?
               } else {
                  longTickets.Delete(i);
               }
            } else if (OrderType()==OP_BUY && OrderCloseTime() != 0) {
               longTickets.Delete(i);
            } else if ( (closeOverWeekend && DayOfWeek()== 5) || closeOverNight) {
               if (!OrderClose(OrderTicket(),OrderLots(),Bid,100,clrGreen)) {
                  PrintFormat("ERROR 002");
               } else {
                  longTickets.Delete(i);
               }
            }
         }
     }
     
     for (int i=shortTickets.Total(); i>=0;i--) {
         if (OrderSelect(shortTickets.At(i),SELECT_BY_TICKET,MODE_TRADES)) {
             if (OrderType() == OP_SELLSTOP) {
               if (!OrderDelete(OrderTicket())) {
                  PrintFormat("ERROR 003");
                  shortTickets.Delete(i); //take profit?
               } else {
                  shortTickets.Delete(i);
               }
            } else if (OrderCloseTime() != 0) {
               shortTickets.Delete(i);
            } else if ( (closeOverWeekend && DayOfWeek()== 5) || closeOverNight) {
               if (!OrderClose(OrderTicket(),OrderLots(),Ask,100,clrGreen)) {
                  PrintFormat("ERROR 004");
               } else {
                  shortTickets.Delete(i);
               }
            }
         }
     }
   } 
   PrintFormat("longtickets in the end: %i", longTickets.Total());
  }
//+------------------------------------------------------------------+
