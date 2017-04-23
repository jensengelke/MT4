//+------------------------------------------------------------------+
//|                                                     gridlike.mq4 |
//|                                                         gridlike |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "gridlike"
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

#include "../Include/JensUtils.mqh";


extern string startTime = "08:00";
extern string endTime = "21:58";
extern double stopAufEinstandBei = 10.0;
extern double riskInPercent = 0.5;
extern double trailInProfit = 30.0;
extern int expiry = 899;
extern double distance = 25.0;
extern double initialStop = 10.0;
extern double takeProfit = 4.0;
extern int myMagic = 201700420;
static datetime lastTradeTime = NULL;

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
   trailInProfit(myMagic,trailInProfit);
   stopAufEinstand(myMagic,stopAufEinstandBei);

   if (Time[0] == lastTradeTime) {
      return;
   }
   
   lastTradeTime = Time[0];
   
   if (OrdersTotal()==0) {
      double tp = 0.0;
      if (takeProfit > 0.0) {
         tp = Ask + distance + takeProfit;
      }
      buyTrigger(Ask + distance, (Ask+distance)-initialStop,tp);
      
      tp = 0.0;
      if (takeProfit > 0.0) {
         tp = Bid - distance - takeProfit;
      }
      sellTrigger(Bid-distance,(Bid-distance)+initialStop, tp);
   }
   
   
  }
//+------------------------------------------------------------------+
//| Timer function                                                   |
//+------------------------------------------------------------------+
void OnTimer()
  {
//---
   if (!isHandelszeit(startTime,endTime)) {
         closeAllPendingOrders(myMagic);
         closeAllOpenOrders(myMagic);
      return;
   }
  }
//+------------------------------------------------------------------+


void buyTrigger(double price, double stop, double tp) {
   if (price > Ask) {
      double lots = lotsByRisk((price-stop),riskInPercent/100,1);
      PrintFormat("buy: price=%.2f, lots=%.2f, stop=%.2f, tp=%.2f,Ask=%.2f",price,lots,stop,tp,Ask);
      OrderSend(Symbol(),OP_BUYSTOP,lots,price,3, stop,tp,"grid up",myMagic,TimeCurrent()+expiry,clrGreen);
   }   
}

void sellTrigger(double price, double stop, double tp) {
   if (price<Bid) {
     double lots = lotsByRisk((stop-price),riskInPercent/100,1);
     PrintFormat("sell: price=%.2f, lots=%.2f, stop=%.2f, tp=%.2f,Bid=%.2f",price,lots,stop,tp,Bid);
     OrderSend(Symbol(),OP_SELLSTOP,lots,price,3,stop,tp,"grid down",myMagic,TimeCurrent()+expiry,clrRed);
   }
}