//+------------------------------------------------------------------+
//|                                                     simpleMA.mq4 |
//|                                                         simpleMA |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "simpleMA"
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

input string label0 = "" ; //+--- admin ---+
input int    myMagic = 20190317;
input int    tracelevel = 2;
input string chartLabel = "simple MA";

input string label1 = "" ; //+--- entry signal ---+
input int    maPeriod = 60;
input int    rsiPeriod = 2;
input double rsiThreshold = 10.0;

input string label2 = ""; //+--- money management ---+
input double emergencyStop = 0.5;
input double lots = 0.1;

static datetime lastTradeTime = NULL;


//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
   
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
   
   double ma = iMA(_Symbol,PERIOD_CURRENT,maPeriod,0,MODE_EMA,PRICE_CLOSE,1); 
   double maPrev = iMA(_Symbol,PERIOD_CURRENT,maPeriod,0,MODE_EMA,PRICE_CLOSE,2);
   
   double rsi = iRSI(_Symbol,PERIOD_CURRENT,rsiPeriod,PRICE_CLOSE,1);
   
   if ( tracelevel >= 3) PrintFormat("ma=%.5f, maprev = %.5f, rsi=%.5f",ma,maPrev,rsi);
   
   if (ma > maPrev) {
      if (rsi < rsiThreshold) {
         exitShort();
         entryLong();
         
      }
   }
   
   if (ma < maPrev) {
      if (rsi > (100 - rsiThreshold)) {
         entryShort();
         exitLong();
      }
   }
   
  }
//+------------------------------------------------------------------+


void exitShort() {
   if (tracelevel >=2) PrintFormat("exitShort ENTRY");
   for (int i=OrdersTotal();i>=0;i--) {
      if (OrderSelect(i,SELECT_BY_POS)) {
         if (OrderMagicNumber() == myMagic && OrderType() == OP_SELL && OrderCloseTime() == 0) {
            if (!OrderClose(OrderTicket(),OrderLots(),Ask,10,clrRed)) {
               PrintFormat("E0001 cannot close short");
            }
         }
      }
   }
}

void exitLong() {
   if (tracelevel >=2) PrintFormat("exitLong ENTRY");
   for (int i=OrdersTotal();i>=0;i--) {
      if (OrderSelect(i,SELECT_BY_POS)) {
         if (OrderMagicNumber() == myMagic && OrderType() == OP_BUY && OrderCloseTime() == 0) {
            if (!OrderClose(OrderTicket(),OrderLots(),Bid,10,clrGreen)) {
               PrintFormat("E0002 cannot close long");
            }
         }
      }
   }
}

void entryLong() {
   if (tracelevel >=2) PrintFormat("entryLong ENTRY");
   int longTicket = -1;
   for (int i=OrdersTotal();i>=0;i--) {
      if (OrderSelect(i,SELECT_BY_POS)) {
         if (OrderMagicNumber() == myMagic && OrderType() == OP_BUY && OrderCloseTime() == 0) {
            longTicket = OrderTicket();
         }
      }
   }
   
   if (longTicket == -1) {
      if (!OrderSend(_Symbol,OP_BUY,lots,Ask,10,Ask - emergencyStop,0,"MA-RSI",myMagic,0,clrGreen)) {
         PrintFormat("E0003 cannot open long");
      }
   }
   
}

void entryShort() {
   if (tracelevel >=2) PrintFormat("entryShort ENTRY");
   int shortTicket = -1;
   for (int i=OrdersTotal();i>=0;i--) {
      if (OrderSelect(i,SELECT_BY_POS)) {
         if (OrderMagicNumber() == myMagic && OrderType() == OP_SELL && OrderCloseTime() == 0) {
            shortTicket = OrderTicket();
         }
      }
   }
   
   if (shortTicket == -1) {
      if (!OrderSend(_Symbol,OP_SELL,lots,Bid,10,Bid + emergencyStop,0,"MA-RSI",myMagic,0,clrRed)) {
         PrintFormat("E0004 cannot open short");
      }
   }
   
}