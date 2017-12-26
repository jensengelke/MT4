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
extern int maxPos = 25;
extern double buffer = 10.0;
extern int slowSMAperiod = 200;
extern int rsiPeriod = 10;
extern double rsiHigh = 85.0;
extern double rsiLow = 15.0;

extern double takeProfit = 25.0;

extern double adxFilter = 45.0;
extern int adxPeriod = 12;

extern double atrTrailingStopFactor = 15.0;
extern double atrInitialStopFactor = 5.0;
extern int atrPeriod = 12;


extern int trace = 1;

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
   
   if (trace>1) 
      PrintFormat("SMA=%.2f, SMA[1]",sma,prevSma);
   
   if (atrTrailingStopFactor > 0.0) {
      trailByATR(myMagic,atrPeriod,PERIOD_D1,atrTrailingStopFactor);
   } else {
      trailInProfit(myMagic,trailInProfit);
   }
   stopAufEinstand(myMagic,stopAufEinstandBei);
   
   double rsi = iRSI(Symbol(),PERIOD_CURRENT,rsiPeriod,PRICE_CLOSE,1);
   double prevRsi = iRSI(Symbol(),PERIOD_CURRENT,rsiPeriod,PRICE_CLOSE,2);
   double risk = currentRisk(myMagic);
   int positionsAtRisk = atRiskPositions(myMagic);
   
   if (trace>1) 
         PrintFormat("rsi=%.2f,rsi[1]=%.2f, risk=%.2f",rsi,prevRsi, risk);
      
   bool allowByAdx = true;
   if (adxFilter > 0.0) {
      allowByAdx = iADX(Symbol(),PERIOD_CURRENT,adxPeriod,PRICE_CLOSE,MODE_MAIN,0) > adxFilter;
   }
   
   if (sma > prevSma) {
   
      if (currentDirectionOfOpenPositions(myMagic)<0 && Close[0]>(sma-buffer)) {
         closeShortPositions(myMagic);
      }
      
      
         
      if (  allowByAdx && 
            prevRsi < rsiLow && 
            rsi>prevRsi &&
            risk <=0 && 
            countOpenPositions(myMagic) < maxPos &&
            currentRisk(myMagic) <= 0 &&
            positionsAtRisk <=1 &&
            Close[0]>sma) {
         
         int openPos = countOpenPositions(myMagic);
            
         double price = Ask;
         double stop = price - initialStop ;
         if (atrInitialStopFactor > 0) {
            stop = price - (atrInitialStopFactor * iATR(Symbol(),PERIOD_D1,atrPeriod,0));
         }
         double lots = fixedLots;
         if (lots == 0) {
            if (openPos < 3) {
               lots = lotsByRisk(initialStop,riskInPercent,lotDigits);
            } else {
               double securedProfit = securedProfit(myMagic);
               if (AccountEquity()*riskInPercent/2 > securedProfit) {
                  if (trace>0) 
                     PrintFormat("Skipping signal, (half of) locked in profit %.2f is less than %i percent of equity (%.2f): %.2f",securedProfit,riskInPercent,AccountEquity(),(riskInPercent*AccountEquity()));
               } else {
                  double riskInPercentByProfit = (0.5*securedProfit) / AccountEquity();
                  lots = lotsByRisk(initialStop,riskInPercentByProfit,lotDigits);
                  
                  if (trace>0) 
                     PrintFormat("Trading signal, (half of) locked in profit %.2f is more than %i percent of equity (%.2f): %.2f",securedProfit,riskInPercent,AccountEquity(),(riskInPercent*AccountEquity()));
               }
            }  
         }
         
         if (lots>0) {
            if (trace>0) {
               PrintFormat("buying %.1f lots at %.2f with stop at %.2f", lots,price,stop);
            }
            double tp = 0.0;
            if (takeProfit > 0) {
               tp = price + takeProfit;
            }
            OrderSend(Symbol(),OP_BUY,lots,price,3,stop,tp,"simple MA RSI",myMagic,0,clrGreen);
         }
      } 
      
   }
   if (sma < prevSma) {
      if (currentDirectionOfOpenPositions(myMagic)>0  && Close[0] < (sma-buffer)) {
         closeLongPositions(myMagic);
      }
      
      if (  allowByAdx && 
            prevRsi > rsiHigh &&
            rsi < prevRsi &&
            risk <=0 && 
            countOpenPositions(myMagic) < maxPos  && 
            currentRisk(myMagic) <= 0 &&
            positionsAtRisk <=1 &&
            Close[0] < sma) {
         double price = Bid;
         double stop = price + initialStop;
         if (atrInitialStopFactor > 0) {
            stop = price + (atrInitialStopFactor * iATR(Symbol(),PERIOD_D1,atrPeriod,0));
         }
         double lots = fixedLots;
         int openPos = countOpenPositions(myMagic);
         
          if (lots == 0) {
            if (openPos < 3) {
               lots = lotsByRisk(initialStop,riskInPercent,lotDigits);
            } else {
               double securedProfit = securedProfit(myMagic);
               //if (AccountEquity()*riskInPercent/2 < 0.5*securedProfit) {
               if (AccountEquity()*riskInPercent/2 < securedProfit) {
                  PrintFormat("Skipping signal, (half of) locked in profit %.2f is less than %i percent of equity (%.2f): %.2f",securedProfit,riskInPercent,AccountEquity(),(riskInPercent*AccountEquity()));
               } else {
                  double riskInPercentByProfit = (0.5*securedProfit) / AccountEquity();
                  lots = lotsByRisk(initialStop,riskInPercentByProfit,lotDigits);
                  if (trace>0) 
                     PrintFormat("Trading signal, (half of) locked in profit %.2f is more than %i percent of equity (%.2f): %.2f",securedProfit,riskInPercent,AccountEquity(),(riskInPercent*AccountEquity()));
               }
            }  
         }
         
         if (lots>0) {
            if (trace>0) {
               PrintFormat("selling %.2f lots at %.2f with stop at %.2f", lots,price,stop);
            }
            double tp = 0.0;
            if (takeProfit > 0) {
               tp = price + takeProfit;
            }
            OrderSend(Symbol(),OP_SELL,lots,price,3,stop,0,"simple MA RSI",myMagic,0,clrRed);      
        }
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
