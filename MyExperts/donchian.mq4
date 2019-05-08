//+------------------------------------------------------------------+
//|                                                     donchian.mq4 |
//|                                                         donchian |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "donchian"
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

input string label0 = "" ; //+--- admin ---+
input int myMagic = 20190328;
input int tracelevel = 2;
input string chartLabel = "donchian";

input string label1 = "" ; //+--- entry signal ---+
input int periodTopEntryExponent = 5;
      int periodTopEntry = MathPow(2,periodTopEntryExponent);
input int periodTopExitExponent = 5;
      int periodTopExit = MathPow(2,periodTopExitExponent);
input int periodBottomEntryExponent = 5;
      int periodBottomEntry = MathPow(2,periodBottomEntryExponent);
input int periodBottomExitExponent = 5;
      int periodBottomExit = MathPow(2,periodBottomExitExponent);

input double lots = 0.1;

static datetime lastBar = NULL;

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
   if (Time[0] == lastBar) return;
   lastBar = Time[0];
   
   int longTicket = -1;
   double longStop = -1;
   int shortTicket = -1;
   double shortStop = -1;
   
   for (int i=OrdersTotal();i>=0;i--) {
      if (OrderSelect(i,SELECT_BY_POS)) {
         if (OrderMagicNumber() == myMagic && (OrderType() == OP_BUYSTOP || OrderType() == OP_SELLSTOP)) {
            if (!OrderDelete(OrderTicket(),clrBlack)) Print("E005");
         }
         if (OrderMagicNumber() == myMagic && OrderType() == OP_BUY) {
            longTicket = OrderTicket();
            longStop = OrderStopLoss();
         }
         if (OrderMagicNumber() == myMagic && OrderType() == OP_SELL) {
            shortTicket = OrderTicket();
            shortStop = OrderStopLoss();
         }
        
      }
   }
   
   double topEntry = NormalizeDouble( High[iHighest(_Symbol,PERIOD_CURRENT,MODE_HIGH,periodTopEntry,0)],_Digits);
   double bottomEntry =  NormalizeDouble( Low[iLowest(_Symbol,PERIOD_CURRENT,MODE_LOW,periodBottomEntry,0)],_Digits);
   double topExit = NormalizeDouble( High[iHighest(_Symbol,PERIOD_CURRENT,MODE_HIGH,periodTopExit,0)],_Digits);
   double bottomExit =  NormalizeDouble( Low[iLowest(_Symbol,PERIOD_CURRENT,MODE_LOW,periodBottomExit,0)],_Digits);
   
   if (-1 == longTicket) {
      if (!OrderSend(_Symbol,OP_BUYSTOP,lots, topEntry,10,bottomExit,0,"",myMagic,0,clrGreen)) Print("E001");
   } else {
      if (longStop != bottomExit) {
         if (!OrderModify(longTicket,0,bottomExit,0,0,clrGreen)) Print("E002");
      }
   }

   if (-1 == shortTicket) {
      if (!OrderSend(_Symbol,OP_SELLSTOP,lots, bottomEntry,10,topExit,0,"",myMagic,0,clrGreen)) Print("E003");
   } else {
      if (shortStop != topExit) {
         if (!OrderModify(shortTicket,0,topExit,0,0,clrGreen)) Print("E004");
      }
   }
   
  }
//+------------------------------------------------------------------+
