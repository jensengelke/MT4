//+------------------------------------------------------------------+
//|                                                  BackToStart.mq4 |
//|                                                      backToStart |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "WochenExtrem"
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict
#include "../Include/JensUtils.mqh";
extern int myMagic = 201700826;

extern double risk = 1.0;
extern int fixedLots = 0.0;
extern bool trace = true;
extern bool wochenSignale = true;
extern bool tagesSignale = false;

extern double initialStop = 20.0;
extern double initialStopInPercent = 0.5;
extern double takeProfit = 20.0;
extern double stopAufEinstand = 10.0;
extern double trailInProfit = 15.0;
extern double trailInPercent = 0.5;

extern double buffer = 10.0;

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
 
   if (Time[0] == lastTradeTime) {
      return;
   }
   lastTradeTime = Time[0];
   
   if (currentDirectionOfOpenPositions(myMagic)!=0) {   
      stopAufEinstand(myMagic,stopAufEinstand);
      if (trailInPercent > 0) {
         trailInProfit = MathAbs(Bid*(trailInPercent/100));
      }
      trailInProfit(myMagic,trailInProfit);
   } 
   if (currentRisk(myMagic)<=0.0){
      double vorwochenHoch = iHigh(Symbol(),PERIOD_W1,1);
      double vorwochenTief = iLow(Symbol(),PERIOD_W1,1);
      
      double wochenHoch = iHigh(Symbol(),PERIOD_W1,1);
      double wochenTief = iLow(Symbol(),PERIOD_W1,1);
      
      double vortagesHoch = iHigh(Symbol(),PERIOD_D1,1);
      double vortagesTief = iLow(Symbol(),PERIOD_D1,1);
      
      double tagesHoch = iHigh(Symbol(),PERIOD_D1,0);
      double tagesTief = iLow(Symbol(),PERIOD_D1,0);
      
      if (wochenSignale && Low[2] < vorwochenHoch && Close[1] > (vorwochenHoch + buffer)) 
         buy();      
      
      if (wochenSignale && High[2] > vorwochenTief && Close[1] < (vorwochenTief - buffer)) 
         sell();   
         
         
      if (wochenSignale && Low[2] < wochenHoch && Close[1] > (wochenHoch + buffer)) 
         buy();      
              
      if (wochenSignale && High[2] > wochenTief && Close[1] < (wochenTief - buffer)) 
         sell();  
         
      if (tagesSignale && Low[2] < vortagesHoch && Close[1] > (vortagesHoch + buffer)) 
         buy();      
      
      if (tagesSignale && High[2] > vortagesTief && Close[1] < (vortagesTief - buffer)) 
         sell();   
         
         
      if (tagesSignale && Low[2] < tagesHoch && Close[1] > (tagesHoch + buffer)) 
         buy();      
              
      if (tagesSignale && High[2] > tagesTief && Close[1] < (tagesTief - buffer)) 
         sell();   
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

void buy() {
      double lots = fixedLots;
      
      double stop = Ask - initialStop;
      if (initialStopInPercent>0) {
         stop = Ask * (1-(initialStopInPercent/100));
      }
      if (0 == initialStop && initialStopInPercent == 0) 
         stop = iLow(Symbol(),PERIOD_H1,1);
         
      if (lots == 0) 
         lots = lotsByRisk(Ask-stop,risk,lotDigits);
         
      double tp = Ask + takeProfit;
      if (0==takeProfit) 
         tp = 0;
      if (trace) 
         PrintFormat("Buy %.2f at %.2f with stop %.2f and tp %.2f",lots,Ask,stop,tp);
         
      OrderSend(Symbol(),OP_BUY,lots,Ask,3,stop,tp,"Wochenhoch",myMagic,0,clrGreen); 
}

void sell() {
      double lots = fixedLots;
            
      double stop = Bid + initialStop;
      if (initialStopInPercent > 0) 
         stop = Bid * (1+(initialStopInPercent/100));
        
      if (0 == initialStop && 0 == initialStopInPercent) 
         stop = iHigh(Symbol(),PERIOD_H1,1);
      if (lots == 0) 
         lots = lotsByRisk(stop-Bid,risk,lotDigits);
      
      double tp = Bid - takeProfit;
      if (0==takeProfit) 
         tp = 0;
      if (trace) 
         PrintFormat("Sell %.2f at %.2f with stop %.2f and tp %.2f",lots,Bid,stop,tp);
         
      OrderSend(Symbol(),OP_SELL,lots,Bid,3,stop,tp,"Wochentief",myMagic,0,clrGreen);   
}