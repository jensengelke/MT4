//+------------------------------------------------------------------+
//|                                                  Stundentest.mq4 |
//|                                                          DerJens |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "OpeningTest"
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict
#include "../Include/JensUtils.mqh";
extern int myMagic = 201700807;


extern double fixedLots = 0.0;
extern double risk = 1.0;
extern bool trace = true;

extern int wochentag = 5;
extern int entryHour = 21;
extern int entryMin = 00;

extern int exitHour = 21;
extern int exitMin = 55;

extern double initialStop = 10.0;
extern double trail = 20.0;
//extern double takeProfit = 20.0;

extern bool shortTrades = false;

static datetime lastTradeTime = NULL;
static int symbolDigits = -1;
static int lotDigits = -1;

static int ticket = 0;


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
   
   if (entryHour>=exitHour) return(INIT_PARAMETERS_INCORRECT);
   
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
      
      if (DayOfWeek()==wochentag && TimeHour(TimeLocal())==entryHour && TimeMinute(TimeLocal())<=entryMin && ticket == 0) {
         
         double lots = fixedLots;
         if (0==lots) 
            lots = lotsByRisk(initialStop,risk,lotDigits);
            
         if (shortTrades) 
            ticket = OrderSend(Symbol(),OP_SELL,lots,Bid,3,Bid+initialStop,0,NULL,myMagic,0,clrGreen);
         else 
            ticket = OrderSend(Symbol(),OP_BUY,lots,Ask,3,Ask-initialStop,0,NULL,myMagic,0,clrGreen);
      }
   
      if (ticket != 0) {
         trailInProfit(myMagic,trail);
         if (TimeHour(TimeLocal())>exitHour || (TimeHour(TimeLocal())==exitHour && TimeMinute(TimeLocal())>=exitMin)) {
           // OrderSelect(ticket,SELECT_BY_TICKET);
           // OrderClose(ticket,OrderLots(),Bid,3,clrRed);
            closeAllOpenOrders(myMagic);
            ticket = 0;
         }
      }
   
  }
//+------------------------------------------------------------------+
