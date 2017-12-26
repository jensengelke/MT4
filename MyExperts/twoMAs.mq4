//+------------------------------------------------------------------+
//|                                                       twoMAs.mq4 |
//|                                                             Jens |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Jens"
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict


#include "../Include/JensUtils.mqh";


extern string startTime = "08:00";
extern string endTime = "21:58";
extern int myMagic = 20170505;
extern double stopAufEinstandBei = 15.0;
extern double riskInPercent = 1.0;
extern double fixedLots = 0.0;
extern double initialStop = 60.0;
extern double trailInProfit = 100.0;
extern int maxPos = 5;
extern double buffer = 10.0;
extern int slowSMAperiod = 200;
extern int rsiPeriod = 10;
extern double rsiHigh = 85.0;
extern double rsiLow = 15.0;

extern bool trace = false;

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
   //abort at night
   if (!isHandelszeit(startTime,endTime)) {
  //    closeAllOpenOrders(myMagic);
      return;
   }   
      
   if (Time[0] == lastTradeTime) {
      return;
   }
   lastTradeTime = Time[0];
   
   double sma = iMA(Symbol(),PERIOD_CURRENT,slowSMAperiod,0,MODE_SMA,PRICE_CLOSE,1);
   double prevSma = iMA(Symbol(),PERIOD_CURRENT,slowSMAperiod,0,MODE_SMA,PRICE_CLOSE,2); 
   
   if (trace) 
      PrintFormat("SMA=%.2f, SMA[1]",sma,prevSma);
   
   trailInProfit(myMagic,trailInProfit);
   stopAufEinstand(myMagic,stopAufEinstandBei);
   
   double rsi = iRSI(Symbol(),PERIOD_CURRENT,rsiPeriod,PRICE_CLOSE,1);
   double prevRsi = iRSI(Symbol(),PERIOD_CURRENT,rsiPeriod,PRICE_CLOSE,2);
   double risk = currentRisk(myMagic);
   if (trace) 
         PrintFormat("rsi=%.2f,rsi[1]=%.2f, risk=%.2f",rsi,prevRsi, risk);
      
   
   if (sma > prevSma) {
   
      if (currentDirectionOfOpenPositions(myMagic)<0 && Close[0]>(sma-buffer)) {
         closeShortPositions(myMagic);
      }
      
      
         
      if (  prevRsi < rsiLow && 
            rsi>prevRsi &&
            risk <=0 && 
            countOpenPositions(myMagic) < maxPos &&
            //currentDirectionOfOpenPositions(myMagic) >= 0 &&
            currentRisk(myMagic) <= 0 &&
            Close[0]>sma) {
         
         double price = Ask;
         double stop = price - initialStop ;
         double lots = fixedLots;
         if (lots == 0) 
            lots = lotsByRisk(initialStop,riskInPercent,lotDigits);
         if (trace) {
            PrintFormat("buying %.1f lots at %.2f with stop at %.2f", lots,price,stop);
         }
         OrderSend(Symbol(),OP_BUY,lots,price,3,stop,0,"simple MA RSI",myMagic,0,clrGreen);
      } 
      
   }
   if (sma < prevSma) {
      if (currentDirectionOfOpenPositions(myMagic)>0  && Close[0] < (sma-buffer)) {
         closeLongPositions(myMagic);
      }
      
      if (  prevRsi > rsiHigh &&
            rsi < prevRsi &&
            risk <=0 && 
            countOpenPositions(myMagic) < maxPos  && 
            //currentDirectionOfOpenPositions(myMagic) <= 0 &&
            currentRisk(myMagic) <= 0 &&
            Close[0] < sma) {
         double price = Bid;
         double stop = price + initialStop;
         double lots = fixedLots;
         if (lots == 0) 
            lots = lotsByRisk(initialStop,riskInPercent,lotDigits);
         if (trace) {
            PrintFormat("selling %.2f lots at %.2f with stop at %.2f", lots,price,stop);
         }
         OrderSend(Symbol(),OP_SELL,lots,price,3,stop,0,"simple MA RSI",myMagic,0,clrRed);      
      }
   }
   
  }
//+------------------------------------------------------------------+
//| Timer function                                                   |
//+------------------------------------------------------------------+
void OnTimer()
  {
   if (!isHandelszeit(startTime,endTime)) {
   //      closeAllOpenOrders(myMagic);
      return;
   }   
  }
//+------------------------------------------------------------------+
