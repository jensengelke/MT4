//+------------------------------------------------------------------+
//|                                              follow-the-bars.mq4 |
//|                        Copyright 2019, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2019, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

input string label0 = "" ; //+--- admin ---+
input int    myMagic = 31;
input int    tracelevel = 2;
input bool   backtest = true; //display balance and equity in chart
input string chartLabel = "follow the bars";

input string label1 = "" ; //+--- entry signal ---+
input int    startAt = 5;
input double targetPoints = 150.0; 
input double trailingStopPoints = 30.0;
input double initialStopPoints = 30.0;
input double lots = 0.01;
static datetime lastTradeTime = NULL;

int longInARow=0;
int shortInARow=0;



//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
   Comment(chartLabel);
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
    
   
   if (Time[0] == lastTradeTime) return;   
   lastTradeTime = Time[0];
   if (backtest) Comment("follow-the-bars, start-at=%i",startAt);
   
   
   trail();
   
   if ( Close[1] > Open[1]) {
      longInARow++;
      shortInARow = 0;
   } else {
      shortInARow++;
      longInARow = 0;
   }
   
   if (longInARow >= startAt) {
      int longOrders = 0;
      for (int i=OrdersTotal();i>=0;i--) {
         if (OrderSelect(i,SELECT_BY_POS)) {
            if (OrderMagicNumber() == myMagic && 
                OrderType() == OP_BUY &&
                OrderCloseTime() == 0) longOrders++;
         }
      }
      if (longOrders<longInARow) {
         double stop =  NormalizeDouble(Ask - (initialStopPoints * _Point),_Digits);
         double tp = NormalizeDouble(Ask + (targetPoints * _Point),_Digits);
         if (!OrderSend(_Symbol,OP_BUY,MathPow(2,longInARow-startAt)*lots,Ask,10,stop,tp,"follow the bars",myMagic,0,clrGreen)) {
            PrintFormat("E0001: cannot buy");
         }
      }
   }
   
   if (shortInARow >= startAt) {
      int shortOrders = 0;
      for (int i=OrdersTotal();i>=0;i--) {
         if (OrderSelect(i,SELECT_BY_POS)) {
            if (OrderMagicNumber() == myMagic && 
                OrderType() == OP_SELL &&
                OrderCloseTime() == 0) shortOrders++;
         }
      }
      if (shortOrders<shortInARow) {
         double stop =  NormalizeDouble(Bid + (initialStopPoints * _Point),_Digits);
         double tp = NormalizeDouble(Bid - (targetPoints * _Point),_Digits);
         if (!OrderSend(_Symbol,OP_SELL,MathPow(2,shortInARow-startAt)*lots,Ask,10,stop,tp,"follow the bars",myMagic,0,clrRed)) {
            PrintFormat("E0002: cannot sell");
         }
      }
   }
   
  }
//+------------------------------------------------------------------+


void trail() {
   if (trailingStopPoints == 0) return;  
   double longStop = Ask - (trailingStopPoints * _Point);
   double shortStop = Bid +  (trailingStopPoints * _Point);
   
   for (int i=OrdersTotal();i>=0;i--) {
      if (OrderSelect(i,SELECT_BY_POS)) {
         if (OrderMagicNumber() == myMagic && OrderCloseTime() == 0) {
            if (OrderType() == OP_BUY && OrderStopLoss() < longStop && OrderOpenPrice() < longStop) {
               OrderModify(OrderTicket(),OrderOpenPrice(),longStop,OrderTakeProfit(),0,clrGreen);   
            }
            
            if (OrderType() == OP_SELL && OrderStopLoss() > shortStop && OrderOpenPrice() > shortStop) {
               OrderModify(OrderTicket(),OrderOpenPrice(),shortStop,OrderTakeProfit(),0,clrRed);   
            }
         }
      }
   }      

}