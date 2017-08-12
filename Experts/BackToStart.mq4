//+------------------------------------------------------------------+
//|                                                  BackToStart.mq4 |
//|                                                      backToStart |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "backToStart"
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict#include "../Include/JensUtils.mqh";
extern int myMagic = 201700623;

extern int startMinute = 0;
extern int startHour = 8;
extern int expiraton = 36000;
extern int closeHour = 17;
extern int closeMinute = 45;
extern double maxRange = 40.0;
extern double risk = 1.0;
extern int numberOfPositions = 3;
extern double distance = 10.0;

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
   
   if (TimeCurrent() == lastTradeTime) {
      return;
   }
   lastTradeTime = TimeCurrent();
   
   int hour = TimeHour(TimeLocal());
   int min  = TimeMinute(TimeLocal());
   
   if (hour < startHour) return; 
   if (hour == startHour && min < startMinute) return;
   
   if (hour>closeHour) return;
   if (hour == closeHour && min >= closeMinute) {
      closeAllOpenOrders(myMagic);
      closeAllPendingOrders(myMagic);
   }
   
   
   
   if (hour == startHour && min == startMinute) {
      if (0==OrdersTotal()) {
         double openHigh = iHigh(Symbol(),PERIOD_D1,0);
         double openLow = iLow(Symbol(),PERIOD_D1,0);
         
         if (openHigh - openLow > maxRange) return;
      
         double price = NormalizeDouble(Ask, symbolDigits);
         double longStop = NormalizeDouble(price - (maxRange),symbolDigits);
         double shortStop = NormalizeDouble(price + (maxRange),symbolDigits);
         
         PrintFormat("starting time... price=%.2f, longStop=%.2f, shortStop=%.2f",price,longStop,shortStop);
         for (int i=0;i<numberOfPositions;i++) {
            double longPrice = NormalizeDouble(price - distance*(i+1),symbolDigits);
            double longLots = lotsByRisk( (longPrice - longStop), NormalizeDouble(risk/numberOfPositions,2),lotDigits);
            double shortPrice = NormalizeDouble(price + distance*(i+1),symbolDigits);
            double shortLots = lotsByRisk( (shortStop - shortPrice), NormalizeDouble(risk/numberOfPositions,2),lotDigits);
            
            PrintFormat("buyLimit: lots=%.2f,price=%.2f",longLots,longPrice);
            OrderSend(Symbol(),OP_BUYLIMIT,longLots,longPrice,3,longStop,price,NULL,myMagic,TimeCurrent() + expiraton,clrGreen);
            PrintFormat("sellLimit: lots=%.2f,price=%.2f", shortLots,shortPrice);
            OrderSend(Symbol(),OP_SELLLIMIT,shortLots,shortPrice,3,shortStop,price,NULL,myMagic,TimeCurrent() + expiraton,clrGreen);
            
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
