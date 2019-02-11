//+------------------------------------------------------------------+
//|                                           mean-reversion-rsi.mq4 |
//|                                                          DerJens |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "DerJens"
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

#include <Arrays/ArrayInt.mqh>

enum ENTRYSIGNAL { ENTRY_LONG, ENTRY_SHORT, ENTRY_NONE };

input string label0 = "" ; //+--- admin ---+
input int    myMagic = 1;
input int    tracelevel = 2;
input bool   backtest = true; //display balance and equity in chart
input string chartLabel = "RSI mean reversion";

input string label1 = "" ; //+--- entry signal ---+
input int    rsiPeriod = 6;
input double rsiDistance = 15.0; //RSI threshold in % from upper and lower end

input string label2 = ""; //+--- money management ---+
input double lots = 0.01;
input double tpPoints = 200;
input int    maxPositions = 3;

input bool   stopAtLastHourExtreme = true;

double rsiLowThreshold = rsiDistance;
double rsiHighThreshold = 100 - rsiDistance;

static datetime lastTradeTime = NULL;

static CArrayInt longTickets;
static CArrayInt shortTickets;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
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
   
   if (backtest) Comment("balance: ", AccountBalance(), ", equity: ", AccountEquity());

   ENTRYSIGNAL entry = entrySignal();
   
   for (int i=shortTickets.Total();i>0;i--) {
     if (OrderSelect(shortTickets.At(i),SELECT_BY_TICKET)) {
         if (OrderCloseTime() != 0) shortTickets.Delete(i); 
     }     
   } 
   
   for (int i=longTickets.Total();i>0;i--) {
     if (OrderSelect(longTickets.At(i),SELECT_BY_TICKET)) {
         if (OrderCloseTime() != 0) longTickets.Delete(i); 
     }     
   } 
   
   if (ENTRY_SHORT == entry) {
      if (longTickets.Total()>0) {
         for (int i=longTickets.Total();i>0;i--) {
           if (OrderSelect(longTickets.At(i),SELECT_BY_TICKET)) {
             OrderClose(OrderTicket(), OrderLots(),Bid,20,clrGreen);
           }
           longTickets.Delete(i);
         }         
      }
      if (shortTickets.Total() < maxPositions) {
         int ticket = sell();
         if (ticket != -1) {
            shortTickets.Add(ticket);
         }
      }
      
   }
   
   if (ENTRY_LONG == entry) {
   
      if (shortTickets.Total()>0) {
         for (int i=shortTickets.Total();i>0;i--) {
           if (OrderSelect(shortTickets.At(i),SELECT_BY_TICKET)) {
             OrderClose(OrderTicket(), OrderLots(),Ask,20,clrGreen);
           }
           shortTickets.Delete(i);
         }         
      }
      
      if (longTickets.Total() < maxPositions) {
         int ticket = buy();
         if (ticket != -1) {
            longTickets.Add(ticket);
         }
      }
      
   }

   
  }
//+------------------------------------------------------------------+


ENTRYSIGNAL entrySignal() {
   if (tracelevel>=2) PrintFormat("entrySignal() > entry");
   ENTRYSIGNAL signal = ENTRY_NONE;
   
   double rsi = iRSI(Symbol(),PERIOD_CURRENT,rsiPeriod,PRICE_CLOSE,1);
   double rsiPrev = iRSI(Symbol(),PERIOD_CURRENT,rsiPeriod,PRICE_CLOSE,2);
   
   if (tracelevel>=2) PrintFormat("entrySignal 2: RSI[1]=%.2f, RSI[2]=%.2f",rsi,rsiPrev);
   
   if (rsi > rsiHighThreshold) signal = ENTRY_SHORT;
   if (rsi < rsiLowThreshold)   signal = ENTRY_LONG;   
   
   if (tracelevel>=2) PrintFormat("entrySignal() < exit: signal=",signal);
   return signal;
}

int sell() {
   double entry = Bid;
   double tp = entry - (tpPoints * _Point);
   double stop = 0;
   if (stopAtLastHourExtreme) {
      stop = iHigh(_Symbol,PERIOD_H4,iHighest(_Symbol,PERIOD_H4,MODE_HIGH,2,0));
   }
   int ticket = OrderSend(Symbol(),OP_SELL,lots,entry,20,stop,tp,"rsi-mean-reversion",myMagic,0,clrRed);         
   return ticket;
}

int buy() {
   double entry = Ask;
   double tp = entry - (tpPoints * _Point);
   double stop = 0;
   if (stopAtLastHourExtreme) {
      stop = iLow(_Symbol,PERIOD_H4,iLowest(_Symbol,PERIOD_H4,MODE_LOW,2,0));
   }
   int ticket = OrderSend(Symbol(),OP_BUY,lots,entry,20,stop,tp,"rsi-mean-reversion",myMagic,0, clrGreen);    
   return ticket;
}