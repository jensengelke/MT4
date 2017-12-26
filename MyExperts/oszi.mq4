//+------------------------------------------------------------------+
//|                                                         oszi.mq4 |
//|                                                Extrem Preisrange |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Extrem Preisrange"
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

#include "../Include/JensUtils.mqh";

extern string startTime = "00:00";
extern string endTime = "21:50";
extern int myMagic = 20170128;
extern double lots = 2.5;

static datetime lastTradeTime = NULL;
extern double riskSize=0.01;

string screenRect = "Range";

double rangeTop = 0.0;
double rangeBottom = 0.0;
int rangeDay = -1;


//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- create timer
   EventSetTimer(60);
      
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//--- destroy timer
   EventKillTimer();
      
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
     if (!isHandelszeit(startTime,endTime)) {
         closeAllPendingOrders(myMagic);
         closeAllOpenOrders(myMagic);
      return;
   }
   
   double cog = iCustom(Symbol(),PERIOD_CURRENT,"COG",true,5,0,0);
   if (Bid > cog) {
         closeLongPositions(myMagic);
   }
   if (Ask < cog) {   
      closeShortPositions(myMagic);
   }
   
   
   if(lastTradeTime == Time[0]) {
      return;
   } else {
      lastTradeTime = Time[0];
   }
   
   double cogHigh = iCustom(Symbol(),PERIOD_CURRENT,"COG",true,5,5,0);
   
   
   
   if (High[1] > cogHigh) {
      if (OrdersTotal() < 3) {
         OrderSend(Symbol(),OP_SELL,lots,Bid,3,Bid + 0.03,0,NULL,myMagic,0,clrRed);
      }
   } else {
      double coglow = iCustom(Symbol(),PERIOD_CURRENT,"COG",true,5,6,0);
   
      if (Low[1] < coglow) {   
         if (OrdersTotal() < 3) {
            OrderSend(Symbol(),OP_BUY,lots,Ask,3,Ask - 0.03,0,NULL,myMagic,0,clrGreen);
         }
      }  
   }
      
   
   
  }
//+------------------------------------------------------------------+
//| Timer function                                                   |
//+------------------------------------------------------------------+
void OnTimer()
  {
//---
   Print("timer event triggered at ", TimeCurrent());
  }
//+------------------------------------------------------------------+
