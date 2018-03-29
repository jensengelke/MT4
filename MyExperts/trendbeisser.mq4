//+------------------------------------------------------------------+
//|                                                 trendbeisser.mq4 |
//|                                                     trendbeisser |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "trendbeisser"
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

#include "../../Include/MyInclude/JensUtils.mqh";
extern int myMagic = 201803222;
extern int smaPeriod = 150;
extern double minAdx = 20.0;
extern double rsiLow = 30.0;
extern double rsiHigh = 80.0;
extern double lots = 0.2;
extern double atrStopFactor = 1.5;
extern double atrProfitFactor = 1.5;
extern int rsiPeriod = 8;

static datetime lastTradeTime = NULL;



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
   if (Time[0] == lastTradeTime) return;
   lastTradeTime = Time[0];
   
   double ma = iMA(Symbol(),PERIOD_CURRENT,smaPeriod,0,MODE_SMA,PRICE_CLOSE,0);
   double adx = iADX(Symbol(),PERIOD_CURRENT,14,PRICE_CLOSE,MODE_MAIN,0);
   double rsi = iRSI(Symbol(),PERIOD_CURRENT,rsiPeriod,PRICE_CLOSE,0);
   double rsiPrev = iRSI(Symbol(),PERIOD_CURRENT,rsiPeriod,PRICE_CLOSE,1);
   
   if (rsi < rsiHigh & rsiPrev > rsiHigh) {
      closeShortPositions(myMagic);
   }
   
   if (rsi > rsiLow & rsiPrev < rsiLow) {
      closeLongPositions(myMagic);
   }
   
   if (
       Close[1]>ma 
       & adx > minAdx
       & rsi < rsiLow
       & countOpenLongPositions(myMagic) == 0   ) {
       
       double stop = Ask - atrStopFactor * iATR(Symbol(),PERIOD_CURRENT,5,0);
       double profit = Ask + atrProfitFactor *iATR(Symbol(),PERIOD_CURRENT,5,0);
      PrintFormat("BUY Ask=%5f, stop = %2f,profit: %.2f",Ask,stop,profit);
      OrderSend(Symbol(),OP_BUY,lots,Ask,5,stop,profit,"trendbeisser" + myMagic,myMagic,0,clrGreen);
   }
   
   if (
      Close[1] < ma
      & adx > minAdx
      & rsi > rsiHigh
      & countOpenShortPositions(myMagic) == 0   ) {
       double stop =  Bid + atrStopFactor * iATR(Symbol(),PERIOD_CURRENT,5,0);
       double profit = Bid - atrProfitFactor * iATR(Symbol(),PERIOD_CURRENT,5,0);
       PrintFormat("Sell Bid=%5f, stop=%5f, tp=%2f",Bid,stop,profit);
       OrderSend(Symbol(),OP_SELL,lots,Bid,5,stop,profit,"trendbeisser"+myMagic,myMagic,0,clrRed); 
   }
   
   
  }