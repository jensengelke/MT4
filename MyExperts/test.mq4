//+------------------------------------------------------------------+
//|                                                         test.mq4 |
//|                                                          DerJens |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "DerJens"
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

datetime barTime = NULL;
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
   if (Time[0] == barTime) return;
   
   barTime = Time[0];
   PrintFormat("bartime: %i, total orders: %i", barTime, OrdersTotal());
   
   if (OrdersTotal() == 0) {
      OrderSend(Symbol(),OP_BUYSTOP,1.0, NormalizeDouble(Ask * 1.01,_Digits),50,0,0,"test",4711,0,clrNONE);
   } else {
      for (int i=OrdersTotal(); i>=0;i--) {
         OrderSelect(i,SELECT_BY_POS,MODE_TRADES);
         
         if (OrderMagicNumber() == 4711 && OrderType() == OP_BUYSTOP) {
         
            PrintFormat("OrderOpenTime: %i, now: %i, gap: %i", OrderOpenTime(), TimeCurrent(), TimeCurrent() - OrderOpenTime());
            if ((TimeCurrent()-OrderOpenTime()) >= 120) {
               OrderDelete(OrderTicket(),clrNONE);
            }
            
         }
      }
   }
   
   
   
   
   
  }
//+------------------------------------------------------------------+
