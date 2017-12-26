//+------------------------------------------------------------------+
//|                                                  Stundentest.mq4 |
//|                                                          DerJens |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "DerJens"
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict
#include "../Include/JensUtils.mqh";
extern int myMagic = 201700808;

extern string startTime = "08:00";
extern string endTime = "21:58";

//extern double fixedLots = 1.0;
extern double risk = 1.0;
extern bool trace = true;

extern int slowSmoothedMAperiod=200;
extern int fastEmaPeriod = 10;

extern double initialStop = 30.0;
extern double trail = 60.0;
//extern double takeProfit = 20.0;

static datetime lastTradeTime = NULL;
static int symbolDigits = -1;
static int lotDigits = -1;


//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
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
    EventKillTimer();   
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
      if(DayOfWeek()==0 || DayOfWeek()==6) return;
          
      if (TimeCurrent() == lastTradeTime) {
         return;
      }
      lastTradeTime = TimeCurrent();
      
      //abort at night
      if (!isHandelszeit(startTime,endTime)) {
       //  closeAllPendingOrders(myMagic);
       //  closeAllOpenOrders(myMagic);
         return;
      }   
      
      double slow = iMA(Symbol(),PERIOD_CURRENT,slowSmoothedMAperiod,0,MODE_SMMA,PRICE_CLOSE,0);
      double fast = iMA(Symbol(),PERIOD_CURRENT,fastEmaPeriod,0,MODE_EMA,PRICE_CLOSE,0);
      
      double slowPrev = iMA(Symbol(),PERIOD_CURRENT,slowSmoothedMAperiod,0,MODE_SMMA,PRICE_CLOSE,1);
      double fastPrev = iMA(Symbol(),PERIOD_CURRENT,fastEmaPeriod,0,MODE_EMA,PRICE_CLOSE,1);
      
      if (slow > fast && slowPrev < fastPrev) { // short sein
         if (currentDirectionOfOpenPositions(myMagic)>=0) {
            closeLongPositions(myMagic);
            double lots = lotsByRisk(initialStop,risk,lotDigits);
            OrderSend(Symbol(),OP_SELL,lots,Bid,3,Bid+initialStop,0,NULL,myMagic,0,clrRed);
         }
      } else if (slow < fast && slowPrev > fastPrev) { //long sein
         if (currentDirectionOfOpenPositions(myMagic)<=0) {
         double lots = lotsByRisk(initialStop,risk,lotDigits);
            closeShortPositions(myMagic);
            OrderSend(Symbol(),OP_BUY,lots,Ask,3,Ask-initialStop,0,NULL,myMagic,0,clrRed);
         }
      }   
  }
//+------------------------------------------------------------------+
