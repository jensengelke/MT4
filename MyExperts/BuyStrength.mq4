//+------------------------------------------------------------------+
//|                                                  BuyStrength.mq4 |
//|                                                             Jens |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Jens"
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict
#include "../../Include/MyInclude/JensUtils.mqh";
extern int myMagic = 20180118;

extern double risk = 3.0;
extern int fixedLots = 0.0;
extern int tracelevel = 0;

extern double buyImmediatelyBuffer = 15.0;

extern bool macdFilter = false;

extern int strengthPeriod1 = 52;
extern ENUM_TIMEFRAMES entryTimeFrame1 = PERIOD_W1;
extern ENUM_TIMEFRAMES exitTimeFrame1 = PERIOD_D1;
extern int initialStop1 = 1;
extern int trailingStop1 = 2;
extern double trailByAtrFactor = 4.0;
extern int trailByATRPeriod = 12;
extern double minStop1 = 35.0;
extern double maxStop1 = 200.0;

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
   
   closeAllPendingOrders(myMagic);
   if (trailByAtrFactor > 0.0) {
      trailByATR(myMagic,trailByATRPeriod, PERIOD_CURRENT, trailByAtrFactor);
   } else {
      trailWithLastXCandle(myMagic,trailingStop1,exitTimeFrame1);
   }
   
   int highest = iHighest(Symbol(),entryTimeFrame1,MODE_HIGH,strengthPeriod1,0);
   int lowest = iLowest(Symbol(),exitTimeFrame1,MODE_LOW,initialStop1,0);
   
   double high1 = iHigh(Symbol(),entryTimeFrame1,highest);
   double stop1 = iLow(Symbol(),exitTimeFrame1, lowest);
   
   Comment("high1: ", high1, "   highest: ", highest, "   stop1: ",stop1 );
      
   //create new 
   if (currentRisk(myMagic)<=0) { //consider open risk?
      if (macdFilter && iMACD(Symbol(),PERIOD_CURRENT,12,26,9,PRICE_CLOSE,MODE_SIGNAL,0) <0) return;
   
      
      
      if ((high1-stop1)<minStop1) stop1=high1-minStop1;
      if ((high1-stop1)>maxStop1) stop1=high1-maxStop1;
      
      if (tracelevel > 0) 
         PrintFormat("buying strength at high=%.2f with stop at %.2f, Ask=%.2f",high1,stop1, Ask);
      
      if ((Ask+buyImmediatelyBuffer) > high1) {
         double lots = lotsByRisk((Ask-stop1),risk,lotDigits);
         if (tracelevel > 0) 
            PrintFormat("buying %.2f lots immediately at Ask=%.2f",lots,Ask);
         
         OrderSend(Symbol(),OP_BUY,lots,Ask,3,stop1,0,"Buy stregnth",myMagic,0,clrGreen);
      } else {
         double lots = lotsByRisk((high1-stop1),risk,lotDigits);
         int expirationTime = 0; //12 * 3600;
         if (tracelevel > 0) 
            PrintFormat("stop buying strength lots=%.2f at high=%.2f and stop=%.2f (current Ask=%.2f) with expiration at %i",lots,high1, stop1, Ask, expirationTime);
      
         OrderSend(Symbol(),OP_BUYSTOP,lots,high1,5.0,stop1,0,"Buy strength",myMagic,expirationTime,clrGreen);
      }
   }
   
   
   
  }
//+------------------------------------------------------------------+
