//+------------------------------------------------------------------+
//|                                                  BackToStart.mq4 |
//|                                                      backToStart |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "backToStart3"
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict
#include "../Include/JensUtils.mqh";
extern int myMagic = 201700719;

extern string startAt = "10:20";
extern string flatAfter = "21:45";

extern double maxHourRange = 30.0;
extern double maxAtr = 7.0;
extern int atrPeriod = 12;

extern double maxStdDev = 10.0;
extern int stdDevPeriod=12;

extern int stochasticK = 20;
extern int stochasticD = 12;


extern double risk = 1.0;
extern int fixedLots = 0.0;
extern bool trace = true;

extern double initialStop = 20.0;
extern double takeProfit = 20.0;
extern double stopAufEinstand = 10.0;
extern double trailInProfit = 15.0;

static datetime lastTradeTime = NULL;
static int symbolDigits = -1;
static int lotDigits = -1;


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

   symbolDigits = MarketInfo(Symbol(),MODE_DIGITS);
   PrintFormat("initialized with lotDigits=%i and symboleDigits=%i",lotDigits,symbolDigits);
   
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
   if(DayOfWeek()==0 || DayOfWeek()==6) return;
   if(!isHandelszeit(startAt,flatAfter)) {
      closeAllOpenOrders(myMagic);
      closeAllPendingOrders(myMagic);
      return;
   }
   
   stopAufEinstand(myMagic,stopAufEinstand);
   trailInProfit(myMagic,trailInProfit);
   
   if (Time[0] == lastTradeTime) {
      return;
   }
   lastTradeTime = Time[0];
   
   
   
   if (isRuhig()) {
      
      double stoch = iStochastic(Symbol(),PERIOD_CURRENT,stochasticK,stochasticD,3,MODE_SMA,1,MODE_MAIN,0);
      double stochPrev = iStochastic(Symbol(),PERIOD_CURRENT,stochasticK,stochasticD,3,MODE_SMA,1,MODE_MAIN,1);
      
            
      if (stochPrev > 80 && stoch < stochPrev) {
         //short
        // closeLongPositions(myMagic);
         if (currentDirectionOfOpenPositions(myMagic) == 0) {
            double lots = fixedLots;
            if (lots == 0) 
               lots = lotsByRisk(initialStop,risk,lotDigits);
            double stop = Bid + initialStop;
            double tp = Bid - takeProfit;
            if (trace) 
               PrintFormat("Sell %.2f at %.2f with stop %.2f and tp %.2f",lots,Bid,stop,tp);
               
            OrderSend(Symbol(),OP_SELL,lots,Bid,3,stop,tp,"ruhige Kugel short",myMagic,0,clrRed);
         }
      }
      
      if (stochPrev < 20 && stoch > stochPrev) {
         //long
         //closeShortPositions(myMagic);
         if (currentDirectionOfOpenPositions(myMagic) == 0) {
            double lots = fixedLots;
            if (lots == 0) 
               lots = lotsByRisk(initialStop,risk,lotDigits);
            double stop = Ask - initialStop;
            double tp = Ask + takeProfit;
            if (trace) 
               PrintFormat("Buy %.2f at %.2f with stop %.2f and tp %.2f",lots,Ask,stop,tp);
               
            OrderSend(Symbol(),OP_BUY,lots,Ask,3,stop,tp,"ruhige Kugel long",myMagic,0,clrGreen);
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
   
  }
//+------------------------------------------------------------------+


bool isRuhig() {
   bool ruhig = true;
   if (maxHourRange>0.0) {
      double hourLow = iLow(Symbol(),PERIOD_H1,1);
      double hourHigh = iHigh(Symbol(),PERIOD_H1,1);
      if (hourHigh - hourLow > maxHourRange) ruhig = false;
   }
   
   if (ruhig && maxAtr >0) {
      double atr = iATR(Symbol(),PERIOD_CURRENT,atrPeriod,0);
      if (atr > maxAtr) ruhig = false;
   }
   
   if (ruhig && maxStdDev>0) {
      double stdDev = iStdDev(Symbol(),PERIOD_CURRENT,stdDevPeriod,0,MODE_EMA,PRICE_CLOSE,0);
      if (stdDev > maxStdDev) ruhig = false;
   }
   
   return ruhig;
}