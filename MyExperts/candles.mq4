//+------------------------------------------------------------------+
//|                                                      candles.mq4 |
//|                                                          candles |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "candles"
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

#include "../Include/JensUtils.mqh";


extern string startTime = "00:15";
extern string endTime = "23:30";
extern double atrPeriod = 12;
extern double riskInPercent = 1.0;
extern double macdMaxValue = 0.00034;
extern int myMagic = 201700524;
extern double minAtrValue = 0.0005;
static datetime lastTradeTime = NULL;
extern bool debug=true;
extern int expiry = 899;
extern double buffer = 0.0002;
extern double triggerIfCloseWithingRange = 0.2;
extern double minCandleBodySize = 0.8;
extern double minCandleSizeInPercentOfATR = 0.8;
extern double trailInProfit = 0.001;
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
//+------------------------------------------------------------------+
void OnTick()
  {
//---
    if (!isHandelszeit(startTime,endTime)) {
         closeAllPendingOrders(myMagic);
         closeAllOpenOrders(myMagic);
      return;
   }
      
   stopAufEinstand(myMagic,trailInProfit);
   
  
   if (Time[0] == lastTradeTime) {
      return;
   }
   
   lastTradeTime = Time[0];
   if (0<countOpenPositions(myMagic)) {return;}
   
   double atr=iATR(Symbol(),PERIOD_CURRENT,atrPeriod,0);
   
   if (atr < minAtrValue) { return; }
   
   double macd = iMACD(Symbol(),PERIOD_CURRENT,12,26,9,PRICE_CLOSE,MODE_SIGNAL,0);
   
   if (macd > macdMaxValue) { return;}
   
   double ma=iMA(Symbol(),PERIOD_CURRENT,12,0,MODE_EMA,PRICE_CLOSE,0);
   
   
      if (Close[1] > ma + atr) {
         double stop = High[iHighest(Symbol(),PERIOD_CURRENT,MODE_HIGH,10,1)];
         double tp = ma -atr;
         sell(stop,tp);
      }
      
      if (Close[1] < ma - atr) {
         double stop = Low[iLowest(Symbol(),PERIOD_CURRENT,MODE_LOW,10,1)];
         double tp = ma + atr;
         buy(stop,tp);
      }
   
   
   
  }
void OnTimer()
  {
//---
   if (!isHandelszeit(startTime,endTime)) {
         closeAllPendingOrders(myMagic);
         closeAllOpenOrders(myMagic);
      return;
   }
  }

void sell(double stop, double tp) {
      stop  = NormalizeDouble(stop,SymbolInfoInteger(Symbol(),SYMBOL_DIGITS));
      double lots = lotsByRisk(MathAbs(stop-Bid),riskInPercent,lotDigits);
      if (debug) {
         PrintFormat("price=%.5f,stop=%.5f,lots=%.5f",Bid,stop,lots);
      }
      OrderSend(Symbol(),OP_SELL,lots,Bid,3, stop,tp,"grid up",myMagic,0,clrGreen);
}

void buy(double stop, double tp) {
      double lots = lotsByRisk(MathAbs(Ask-stop),riskInPercent,lotDigits);
      if (debug) {
         PrintFormat("price=%.5f,stop=%.5f,lots=%.5f",Ask,stop,lots);
      }
      OrderSend(Symbol(),OP_BUY,lots,Ask,3, stop,tp,"grid up",myMagic,0,clrGreen);
}

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
void buyLimitTrigger(double price, double stop, double tp) {
   if (price < Ask) {
      price = NormalizeDouble(price,5);
      double lots = lotsByRisk((price-stop),riskInPercent,lotDigits);
      PrintFormat("buy: price=%.5f, lots=%.5f, stop=%.5f, tp=%.5f,Ask=%.5f",price,lots,stop,tp,Ask);
      OrderSend(Symbol(),OP_BUYLIMIT,lots,price,3, stop,tp,"grid up",myMagic,TimeCurrent()+expiry,clrGreen);
   }   
}

void sellLimitTrigger(double price, double stop, double tp) {
   if (price>Bid) {
     price = NormalizeDouble(price,5);
     double lots = lotsByRisk((stop-price),riskInPercent,lotDigits);
     PrintFormat("sell: price=%.5f, lots=%.5f, stop=%.5f, tp=%.5f,Bid=%.5f",price,lots,stop,tp,Bid);
     OrderSend(Symbol(),OP_SELLLIMIT,lots,price,3,stop,tp,"grid down",myMagic,TimeCurrent()+expiry,clrRed);
   }
}
