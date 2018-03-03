//+------------------------------------------------------------------+
//|                                                      scalper.mq4 |
//|                                                             Jens |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Jens"
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict
#include "../../Include/MyInclude/JensUtils.mqh";
extern int myMagic = 20180211;

extern double risk = 1.0;
extern int tracelevel = 2;

extern double candleBodySizeInPercent = 0.7;
extern double minCandleSize = 15.0;
extern double targetATRFactor = 0.5;
extern int    targetATRPeriod = 12;
extern int    trailingPeriod = 8;
extern int    maxPositionsPerDirection = 5;

static datetime lastTradeTime = NULL;
static int lotDigits = -1;
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
  double lotstep = MarketInfo(Symbol(),MODE_LOTSTEP);
   if (lotstep == 1.0)        lotDigits = 0;
   if (lotstep == 0.1)        lotDigits = 1;
   if (lotstep == 0.01)       lotDigits = 2;
   if (lotstep == 0.001)      lotDigits = 3;
   if (lotstep == 0.0001)     lotDigits = 4;
   if (lotDigits == -1)       return(INIT_FAILED);   
//---
   
   
   PrintFormat("initialized with lotDigits=%i",lotDigits);
   
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+

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
    if (Time[0] == lastTradeTime) {
      return;
   }
   lastTradeTime = Time[0];
   
   trailWithLastXCandle(myMagic, trailingPeriod);
   
   double candleSize = High[1] - Low[1];
   if (candleSize < minCandleSize) return;
   
   double candleBody = MathAbs(Open[1]-Close[1]);
   
   if ((candleBody / candleSize) < candleBodySizeInPercent) return;
   
   double atr = iATR(Symbol(),PERIOD_CURRENT,targetATRPeriod,0);
   
   if (Open[1] > Close[1]) { //short
      if (maxPositionsPerDirection > countOpenShortPositions(myMagic)) {
         double stop = High[1];
         double price = Bid;
         double lots = lotsByRisk(MathAbs(price-stop),risk,lotDigits);
         double tp = price - (atr*targetATRFactor);
         OrderSend(Symbol(),OP_SELL,lots,price,3,stop, tp, "scalper",myMagic,0,clrRed);
      }
   } else { //long
      if (maxPositionsPerDirection > countOpenLongPositions(myMagic)){
         double stop = Low[1];
         double price = Ask;
         double lots = lotsByRisk(MathAbs(price-stop),risk,lotDigits);
         double tp = price + (atr*targetATRFactor);
         OrderSend(Symbol(),OP_BUY,lots,price,3,stop, tp, "scalper",myMagic,0,clrGreen);
      }
   }
  }
//+------------------------------------------------------------------+
