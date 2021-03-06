//+------------------------------------------------------------------+
//|                                                         fees.mq4 |
//|                        Copyright 2019, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2019, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

static datetime lastBar = NULL;
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
//---
   if (Time[0] == lastBar) return;
   
   PrintFormat("tickvalue: %.5f,  pointsize: %.5f, ticksize: %.5f, 64 EUR bei 0.1 lot: %.5f " ,  //0.00724 = .88 / 0.1 * 0.00001
      MarketInfo(_Symbol,MODE_TICKVALUE),  
      MarketInfo(_Symbol,MODE_POINT),
      MarketInfo(_Symbol,MODE_TICKSIZE),
      (64 /(MarketInfo(_Symbol,MODE_TICKVALUE) * 0.1 / MarketInfo(_Symbol,MODE_TICKSIZE))  ));
      
   PrintFormat("0.22 EUR gebühren mit 0.01 lot braucht %.5f",
      (0.22 /(MarketInfo(_Symbol,MODE_TICKVALUE) * 0.01 / MarketInfo(_Symbol,MODE_TICKSIZE))  ));
   
   PrintFormat("3.01 EUR  mit 0.05 lot braucht %.5f", //85-17=0.00068
      (3.01 /(MarketInfo(_Symbol,MODE_TICKVALUE) * 0.05 / MarketInfo(_Symbol,MODE_TICKSIZE))  ));
   
   
  }
//+------------------------------------------------------------------+
