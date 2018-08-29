//+------------------------------------------------------------------+
//|                                                trendFollower.mq4 |
//|                                                          DerJens |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "DerJens"
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict
#include "../../Include/Arrays/ArrayInt.mqh";

input string label0 = "" ; //+--- admin ---+
input int myMagic = 20180824;
input int tracelevel = 2;
input string chartLabel = "trendfollower";

input string label1 = "" ; //+--- entry signal ---+
input int quickEmaPeriod = 20;
input int slowSmoothedMaPeriod = 50;
input int minDistancePoints = 100;

input string label2 = ""; //+--- money management ---+
input double lots = 0.1;
input int stopPoints = 300;

int direction = 0; //-1 = short, 0=neutral, 1=long
double highestEntry = 0.0;
double lowestEntry = 0.0;


static datetime lastTradeTime = NULL;
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
   
   if (quickEmaPeriod > slowSmoothedMaPeriod) return (INIT_PARAMETERS_INCORRECT);
   
   Comment(chartLabel);
   
   PrintFormat("Init: Point=%.5f",_Point);
   
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
   
   double quickMA = iMA(Symbol(),PERIOD_CURRENT,quickEmaPeriod,0,MODE_EMA,PRICE_CLOSE,1);
   double quickMA1 = iMA(Symbol(),PERIOD_CURRENT,quickEmaPeriod,0,MODE_EMA,PRICE_CLOSE,2);
   double slowMA = iMA(Symbol(),PERIOD_CURRENT,slowSmoothedMaPeriod,0,MODE_SMMA,PRICE_CLOSE,1);
   double slowMA1 = iMA(Symbol(),PERIOD_CURRENT,slowSmoothedMaPeriod,0,MODE_SMMA,PRICE_CLOSE,2);
   
   
   if (tracelevel>=2) {
      PrintFormat("quick[1]=%.5f | slow[1]=%.5f | quick[0]=%.5f | slow[0]=%.5f",
      quickMA1,slowMA1,quickMA,slowMA);
   }
   
  
   
   
   if (quickMA1 > slowMA1 && quickMA < slowMA) {
      close();      
      double entry = NormalizeDouble(Bid, _Digits);
      double stop = NormalizeDouble(Ask,_Digits) + (stopPoints*_Point);
      sell(entry,stop,lots);        
   }
   
   if (quickMA1 < slowMA1 && quickMA > slowMA) {
      close();
      double entry = NormalizeDouble(Ask, _Digits);
      double stop = NormalizeDouble(Bid,_Digits) - (stopPoints*_Point);
      buy(entry,stop,lots);
        
   }
   
  }
//+------------------------------------------------------------------+


void sell(double entry, double stop, double size) {
   
   int ticket = OrderSend(Symbol(),OP_SELL,size,entry,100,stop,0,"trendfollowing",myMagic,0,clrRed);
   if (ticket > -1) {
      
   } else {
      PrintFormat("ERROR");
   }
}

void buy(double entry, double stop, double size) {
   int ticket = OrderSend(Symbol(),OP_BUY,size,entry,100,stop,0,"trendfollowing",myMagic,0,clrRed);
   if (ticket > -1) {
      
   } else {
      PrintFormat("ERROR");
   }
}


void close() {
  for (int i=OrdersTotal();i>=0;i--) {
      
      if (OrderSelect(i,SELECT_BY_POS) && OrderCloseTime()==0 && OrderMagicNumber() == myMagic && OrderSymbol() == Symbol()) {
         if (!OrderClose(OrderTicket(),OrderLots(),Bid,100,NULL)) {
            PrintFormat("ERROR!");
         } 
      }
   }  
}