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


extern string startTime = "00:15";
extern string endTime = "23:30";
extern double atrPeriod = 12;
extern double riskInPercent = 1.0;
extern int expiry = 899;
extern double trailInProfit = 0.0001;
extern double distanceATRFactor = 0.3;
extern double trendInitialStopATRFactor = 0.6;
extern double trendTakeProfitATRFactor = 0.3;
extern int myMagic = 201700420;
extern double minAtrValue = 0.0005;
static datetime lastTradeTime = NULL;
extern bool debug=true;



int lotDigits = -1;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- create timer
   EventSetTimer(60);
   double lotstep = MarketInfo(Symbol(),MODE_LOTSTEP);
   if (lotstep == 1.0)        lotDigits = 0;
   if (lotstep == 0.1)        lotDigits = 1;
   if (lotstep == 0.01)       lotDigits = 2;
   if (lotstep == 0.001)      lotDigits = 3;
   if (lotstep == 0.0001)     lotDigits = 4;
   if (lotDigits == -1)       return(INIT_FAILED);   
   
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
//+-----------------^-------------------------------------------------+
void OnTick()
  {

    if (!isHandelszeit(startTime,endTime)) {
         closeAllPendingOrders(myMagic);
         closeAllOpenOrders(myMagic);
      return;
   }
   
   double atr=iATR(Symbol(),PERIOD_CURRENT,atrPeriod,0);
   trailInProfit(myMagic,trailInProfit);
  
   if (Time[0] == lastTradeTime) {
      return;
   }
   
   if (atr < minAtrValue) {
      return;
   }
   
   lastTradeTime = Time[0];
     
   if (OrdersTotal()==0) {
      
         double price =  Ask + distanceATRFactor * atr;
         double tp = price + atr*trendTakeProfitATRFactor;         
         double stop = price - atr*trendInitialStopATRFactor;
         if (debug) {
            PrintFormat("buytrigger price=%.5f, stop=%.5f,tp=%.5f. atr=%.2f",price,stop,tp,atr);
         }
         buyTrigger(price, stop,tp);
      
         price = Bid  - distanceATRFactor * atr;
         tp = price - atr*trendTakeProfitATRFactor;
         stop = price + atr*trendInitialStopATRFactor;
         if (debug) {
            PrintFormat("sell trigger price=%.5f, stop=%.5f,tp=%.5f",price,stop,tp);
         }
         sellTrigger(price, stop, tp);
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
      price = NormalizeDouble(price,SymbolInfoInteger(Symbol(),SYMBOL_DIGITS));
      double lots = lotsByRisk((price-stop),riskInPercent,lotDigits);
      //PrintFormat("buy: price=%.5f, lots=%.5f, stop=%.5f, tp=%.5f,Ask=%.5f",price,lots,stop,tp,Ask);
      OrderSend(Symbol(),OP_BUYSTOP,lots,price,3, stop,tp,"grid up",myMagic,TimeCurrent()+expiry,clrGreen);
   }   
}

void sellTrigger(double price, double stop, double tp) {
   if (price<Bid) {
     price = NormalizeDouble(price,5);
     double lots = lotsByRisk((stop-price),riskInPercent,lotDigits);
     //PrintFormat("sell: price=%.5f, lots=%.5f, stop=%.5f, tp=%.5f,Bid=%.5f",price,lots,stop,tp,Bid);
     OrderSend(Symbol(),OP_SELLSTOP,lots,price,3,stop,tp,"grid down",myMagic,TimeCurrent()+expiry,clrRed);
   }
}
