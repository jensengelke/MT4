//+------------------------------------------------------------------+
//|                                                 MA-crossover.mq4 |
//|                                                          DerJens |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "DerJens"
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

input string label0 = "" ; //+--- admin ---+
input int    myMagic = 10;
input int    tracelevel = 2;
input bool   backtest = true; //display balance and equity in chart
input string chartLabel = "MA Cross Over";

input string label1 = "" ; //+--- entry signal ---+
input int    slowMAPeriod = 48;
input int    fastMAPeriod = 16; 

input string label2 = ""; //+--- money management ---+
input double lots = 0.1;
input int    positions = 10;

static int ticket = -1;
static datetime lastTradeTime = NULL;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
  Comment(chartLabel);
  
  if (fastMAPeriod > (slowMAPeriod/2)) return INIT_PARAMETERS_INCORRECT;
  
  for (int i=OrdersTotal(); i>=0;i--) {
   if (OrderSelect(i,SELECT_BY_POS)) {
      if (OrderSymbol() != _Symbol) continue;
      if (OrderMagicNumber() != myMagic) continue;
      ticket = OrderTicket();
      break;
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
      
      double fastMA = iMA(_Symbol,PERIOD_CURRENT,fastMAPeriod,0,MODE_EMA,PRICE_CLOSE,1);
      double slowMA = iMA(_Symbol,PERIOD_CURRENT,slowMAPeriod,0,MODE_SMA,PRICE_CLOSE,1);
      
      if (fastMA > slowMA && Low[1] > slowMA) goLong();
      if (fastMA < slowMA && High[1]< slowMA) goShort();  
   
  }
//+------------------------------------------------------------------+

void goLong() {
   int isLong = 0;
   bool counter = false;
   for (int i=OrdersTotal();i>=0;i--) {
      if (OrderSelect(i,SELECT_BY_POS)) {
         if (OrderType() == OP_SELL) { // && !counter) {
            if (OrderClose(OrderTicket(),OrderLots(),Ask,20,clrRed)) {
               counter = true;
            } else {
               Print("ERROR 001");
            }
         }
         if (OrderType() == OP_BUY) isLong++;
      }
   }
   if (isLong<positions) {
      ticket = OrderSend(_Symbol,OP_BUY,lots,Ask,20,0,0,"MA cross",myMagic,0,clrGreen);
   }
}


void goShort() {
   int isShort = 0;
   bool counter = false;
   for (int i=OrdersTotal();i>=0;i--) {
      if (OrderSelect(i,SELECT_BY_POS)) {
         if (OrderType() == OP_BUY) { // && !counter) {
            if (OrderClose(OrderTicket(),OrderLots(),Bid,20,clrRed)) {
               counter = true;
            } else {
               Print("ERROR 002");
            }
         }
         if (OrderType() == OP_SELL) isShort++;
      }
   }
      
   
   if (isShort<positions) {
      ticket = OrderSend(_Symbol,OP_SELL,lots,Bid,20,0,0,"MA cross",myMagic,0,clrGreen);
   }

}