//+------------------------------------------------------------------+
//|                                        trendfollowerEURUSDM5.mq4 |
//|                                            trendfollowerEURUSDM5 |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "trendfollowerEURUSDM5"
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

#include "../Include/JensUtils.mqh";
extern string startTime = "01:00";
extern string endTime = "23:00";
extern int myMagic = 201700603;

extern double tp = 0.0225;
extern double trailInProfit = 0.003;
extern double minRangeFactor = 3.0;
extern double riskInPercent = 1.0;
extern int rangePeriods = 8;
extern int maxPositions = 4;

static double maxCandle = 0.0;
static int maxCandlePos = 0;

int lotDigits=2;
extern bool trace = false;

static int lastMinutes = -1;
static datetime lastTradeTime = NULL;
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
   //abort at night
   if (!isHandelszeit(startTime,endTime)) {
      closeAllPendingOrders(myMagic);
      closeAllOpenOrders(myMagic);
      return;
   }   
      
   //act at most once per minute
   if ( TimeMinute(TimeCurrent()) != lastMinutes) {
      lastMinutes = TimeMinute(TimeCurrent());
   } else {
      return;
   }
  
   
   trailInProfit(myMagic,trailInProfit);
   
   //trade more frequently?
   if (Time[0] == lastTradeTime) {
      return;
   }
  
   lastTradeTime = Time[0]; 
   if (trace) {
      PrintFormat("maxCandlePos=%i", maxCandlePos);
   }
   
   if (maxCandlePos == 0 || maxCandlePos >= rangePeriods) {
      maxCandle = 0.0;
      for (int i=2;i<rangePeriods;i++) {         
         double candleSize = High[i]-Low[i];
         if (candleSize > maxCandle) {
            maxCandle = candleSize;
            maxCandlePos = i;
         }
      }
   } else {
      maxCandlePos++;
   }
   
   if (countOpenPositions(myMagic) >= maxPositions) { return; }
   
   double candleSize = High[1]-Low[1];
   if (candleSize > (maxCandle*minRangeFactor)) {
      if (Close[1]>Open[1]) {
         double stopDistance = Ask - Low[1];
         double lots = lotsByRisk(stopDistance,riskInPercent,lotDigits);
         OrderSend(Symbol(),OP_BUY,lots,Ask,3,Low[1],Ask+tp,NULL,myMagic,0,clrGreen);
      } else {
         double stopDistance = High[1]-Bid;
         double lots = lotsByRisk(stopDistance,riskInPercent,lotDigits);
         OrderSend(Symbol(),OP_SELL,lots,Bid,3,High[1],Bid-tp,NULL,myMagic,0,clrGreen);
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
