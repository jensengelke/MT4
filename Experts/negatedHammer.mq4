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
extern int myMagic = 201700722;

extern int ma1_period = 5;
extern int ma2_period = 10;
extern int ma3_period = 50;

extern double minCandleBody = 0.5;

extern string startAt = "09:15";
extern string flatAfter = "21:45";
extern double risk = 1.0;
extern double trailInProfit = 20.0;
extern double minStop = 10.0;
extern double takeProfit = 20.0;
extern bool trace = true;

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
   
   if (TimeCurrent() == lastTradeTime) {
      return;
   }
   lastTradeTime = TimeCurrent();
   
   trailInProfit(myMagic,trailInProfit);
   
   if (currentDirectionOfOpenPositions(myMagic)==0) {
      double av1 = iMA(Symbol(),PERIOD_CURRENT,ma1_period,0,MODE_SMA,PRICE_CLOSE,0);
      double av2 = iMA(Symbol(),PERIOD_CURRENT,ma2_period,0,MODE_SMA,PRICE_CLOSE,0);
      double av3 = iMA(Symbol(),PERIOD_CURRENT,ma3_period,0,MODE_SMA,PRICE_CLOSE,0);
      
      bool bull = Close[1] > av1 && Close[1] > av2 && Close[1] > av3;
      bool bear = Close[1] < av1 && Close[1] < av2 && Close[1] < av3;
      
      bool hammerup = MathMin(Open[2],Close[2])>High[2]-(High[2]-Low[2])/3;
      bool hammerupnegated = MathMax(Open[1],Close[1]) < MathMin(Open[2],Close[2]) && MathAbs(Open[1]-Close[1])/(High[1]-Low[1])>minCandleBody;
      bool conditionShort = hammerup && hammerupnegated && bear;

      bool hammerdown = MathMax(Open[2],Close[2]) < Low[2]+(High[2]-Low[2])/3;
      bool hammerdownnegated = MathMin(Open[1],Close[1]) > MathMax(Open[2],Close[2]) && MathAbs(Open[1]-Close[1])/(High[1]-Low[1])>minCandleBody;
      bool conditionLong = hammerdown && hammerdownnegated && bull;
 
      if (conditionShort) {
         double price = Bid;
         double stop = High[2];
         double tp = price - takeProfit;
         if (stop-price < minStop) stop = price+minStop;
         double lots = lotsByRisk(stop-price,risk,lotDigits);
         if (trace) {
            PrintFormat("sell %.2f lots at %.5f with stop %.5f",lots,price,stop);
         }
         
         OrderSend(Symbol(),OP_SELL,lots,price,3,stop,tp,"hammer negated",myMagic,0,clrRed);
      }
      
      if (conditionLong) {
         double price = Ask;
         double stop = Low[2];
         double tp = price + takeProfit;
         if (price-stop < minStop) stop = price-minStop;
         double lots = lotsByRisk(price-stop,risk,lotDigits);
         if (trace) {
            PrintFormat("buy %.2f lots at %.5f with stop %.5f",lots,price,stop);
         }
         
         OrderSend(Symbol(),OP_BUY,lots,price,3,stop,tp,"hammer negated",myMagic,0,clrGreen);
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

