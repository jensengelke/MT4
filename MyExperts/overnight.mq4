//+------------------------------------------------------------------+
//|                                                    overnight.mq4 |
//|                                                        overnight |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "overnight"
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

#include "../Include/JensUtils.mqh";
extern int myMagic = 201700623;

extern int openMinute = 30;
extern int openHour = 17;
extern int closeMinute = 15;
extern int closeHour = 9;
extern int emaPeriod = 50;
extern double minRange = 80.0;
extern double risk = 1.0;
extern double inPercentOfRangeExtreme = 0.2;

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
      if (
         TimeMinute(TimeLocal()) == openMinute && 
         TimeHour(TimeLocal()) == openHour && 
         DayOfWeek()>0 && 
         DayOfWeek()<5 && OrdersTotal()==0) {
        
      double dailyHigh = iHigh(Symbol(),PERIOD_D1,0);
      double dailyLow = iLow(Symbol(),PERIOD_D1,0);
      
      double range = (dailyHigh - dailyLow);
      PrintFormat("Tagesrange: %.2f", range);
      
      if (minRange > range) return;
      
      double ema = iMA(Symbol(),PERIOD_CURRENT,emaPeriod,0,MODE_EMA,PRICE_CLOSE,0);
      double lots = lotsByRisk(inPercentOfRangeExtreme*(dailyHigh-dailyLow),risk,lotDigits);
      double distance = NormalizeDouble(inPercentOfRangeExtreme*range,MarketInfo(Symbol(),MODE_DIGITS));
      
      if (Close[0] > dailyHigh - distance && Close[0] > ema) {
         double stop = NormalizeDouble(dailyHigh - distance,MarketInfo(Symbol(),MODE_DIGITS));
         double tp = NormalizeDouble(Ask *1.015,MarketInfo(Symbol(),MODE_DIGITS));
         PrintFormat("buying: lots=%.2f, Ask=%.2f, stop=%.2f, tp=%.2f",lots,Ask,stop,tp);      
         
         if (MathAbs(Ask-stop)>10.0) {
            OrderSend(Symbol(),OP_BUY,lots,Ask,3, stop, tp,NULL,myMagic,0,clrGreen);
         }
      } else if (Close[0] < dailyLow + 0.2*range && Close[0]<ema) {
         double stop = NormalizeDouble(dailyHigh + distance,MarketInfo(Symbol(),MODE_DIGITS));
         double tp = NormalizeDouble(Bid *0.985,MarketInfo(Symbol(),MODE_DIGITS));
         PrintFormat("Selling: lots=%.2f, Bid=%.2f, stop=%.2f, tp=%.2f",lots,Bid,stop,tp);
         if (MathAbs(Bid-stop)>10.0) {
            OrderSend(Symbol(),OP_SELL,lots,Bid,3, stop,tp,NULL,myMagic,0,clrGreen);
         }
      }
   }
   
   if (
      TimeMinute(TimeLocal()) == closeMinute && 
      TimeHour(TimeLocal()) == closeHour) {
      closeAllOpenOrders(myMagic);
   }
  }
//+------------------------------------------------------------------+
//| Timer function                                                   |
//+------------------------------------------------------------------+
void OnTimer()
  {
//---

  }
//+------------------------------------------------------------------+
