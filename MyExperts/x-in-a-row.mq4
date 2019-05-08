//+------------------------------------------------------------------+
//|                                                   x-in-a-row.mq4 |
//|                        Copyright 2019, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2019, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

input string label0 = "" ; //+--- admin ---+
input int    myMagic = 30;
input int    tracelevel = 2;
input bool   backtest = true; //display balance and equity in chart
input string chartLabel = "X in a row";

input string label1 = "" ; //+--- entry signal ---+
input int    x = 7;
input double targetPoints = 150.0; 
input double trailingStopPoints = 30.0;
input double initialStopPoints = 30.0;
input double lots = 0.1;
input int    barCountForTimeStop = 3;

static datetime lastTradeTime = NULL;

int longInARow=0;
int shortInARow=0;


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
   
   
   if (Time[0] == lastTradeTime) return;   
   lastTradeTime = Time[0];
   if (backtest) Comment("X in a row: x=%i",x);
   
   timeStop();
   trail();
   
   
   if ( Close[1] > Open[1]) {
      longInARow++;
      shortInARow = 0;
   } else {
      shortInARow++;
      longInARow = 0;
   }
   
   if (longInARow > x && currentRisk() <=0.0) {    
      double stop =  NormalizeDouble(Ask - (initialStopPoints * _Point),_Digits);
      double tp = NormalizeDouble(Ask + (targetPoints * _Point),_Digits);
      if (!OrderSend(_Symbol,OP_BUY,lots,Ask,10,stop,tp,"X in a row",myMagic,0,clrGreen)) {
         PrintFormat("E0001: cannot buy");
      }  
   }
   
   if (shortInARow > x && currentRisk() <=0.0) {
      double stop =  NormalizeDouble(Bid + (initialStopPoints * _Point),_Digits);
      double tp = NormalizeDouble(Bid - (targetPoints * _Point),_Digits);
      if (!OrderSend(_Symbol,OP_SELL,lots,Ask,10,stop,tp,"X in a row",myMagic,0,clrGreen)) {
         PrintFormat("E0002: cannot sell");
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

double currentRisk() {
   double currentRisk = 0.0;
   for (int i=OrdersTotal();i>=0;i--) {
      OrderSelect(i,SELECT_BY_POS,MODE_TRADES);
      if (OrderMagicNumber() != myMagic) continue;
      if (OrderSymbol() != Symbol()) continue;
      if (OrderCloseTime()>0) continue;
     
      if (OrderType() == OP_BUY){
         currentRisk+=OrderLots() * (OrderOpenPrice() - OrderStopLoss());
      }
      if (OrderType() == OP_SELL) {
        currentRisk+=OrderLots() * (OrderStopLoss()- OrderOpenPrice());
      }
   }
   return currentRisk;
}

void timeStop() {
   for (int i=OrdersTotal();i>=0;i--) {
      if (OrderSelect(i,SELECT_BY_POS)) {
         if (OrderMagicNumber() == myMagic && OrderCloseTime() == 0) {
          
            if (OrderType() == OP_BUY && iBarShift(_Symbol,PERIOD_CURRENT,OrderOpenTime(),false) > barCountForTimeStop) {
               OrderClose(OrderTicket(),OrderLots(),Bid,10,clrGreen);
            }
            
            if (OrderType() == OP_SELL && iBarShift(_Symbol,PERIOD_CURRENT,OrderOpenTime(),false) > barCountForTimeStop) {
               OrderClose(OrderTicket(),OrderLots(),Ask,10,clrRed);
            }
         }
      }
   } 
}
