//+------------------------------------------------------------------+
//|                                                   pathfinder.mq4 |
//|                                                       pathfinder |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "pathfinder"
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

#include "../Include/JensUtils.mqh";

extern string startTime = "08:00";
extern string endTime = "21:58";
extern int myMagic = 20161217;
extern double riskInPercent = 2;
extern double fixedTakeProfit = 0.0;
extern double initialStop = 60.0;
extern double stopAufEinstandBei = 5.0;
extern double trailInProfit = 30.0;
extern int period = 9;
extern bool CROSS_OVER_DAILY_HIGH_LONG = true;
extern bool CROSS_OVER_DAILY_LOW_LONG = false;
extern bool CROSS_OVER_WEEKLY_HIGH_LONG = true;
extern bool CROSS_OVER_WEEKLY_LOW_LONG = false;
extern bool CROSS_OVER_MONTHLY_HIGH_LONG = true;
extern bool CROSS_OVER_MONTHLY_LOW_LONG = true;

extern bool CROSS_UNDER_DAILY_HIGH_SHORT = false;
extern bool CROSS_UNDER_DAILY_LOW_SHORT = true;
extern bool CROSS_UNDER_WEEKLY_HIGH_SHORT = false;
extern bool CROSS_UNDER_WEEKLY_LOW_SHORT = false;
extern bool CROSS_UNDER_MONTHLY_HIGH_SHORT = true;
extern bool CROSS_UNDER_MONTHLY_LOW_SHORT = true;

extern bool filterUsingMA = true;

extern int filterFastMA = 50;
extern int filterSlowMA = 200;


string screenString = "StatusWindow";
static datetime lastTradeTime = NULL;

double signalLine = 0.0;
double lastSignalLine = 0.0;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
   
//---
   return(INIT_SUCCEEDED);
  }
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
   if (!isHandelszeit(startTime,endTime)) {
       //  closeAllPendingOrders(myMagic);
       //  closeAllOpenOrders(myMagic);
      return;
   }
   
    trailInProfit(myMagic,trailInProfit);
   stopAufEinstand(myMagic,stopAufEinstandBei);
   
   
   if(lastTradeTime == Time[0]) {
      return;
   } else {
      lastTradeTime = Time[0];
   }
   
  
   
   lastSignalLine = signalLine;
   signalLine = iMA(NULL, PERIOD_CURRENT,period,0,MODE_EMA,PRICE_CLOSE,0);
   
   double fastMA = iMA(NULL, PERIOD_CURRENT,filterFastMA,0,MODE_SMA,PRICE_CLOSE,0);
   double slowMA = iMA(NULL,PERIOD_CURRENT,filterSlowMA,0,MODE_SMA,PRICE_CLOSE,0);
   
   double dailyHigh = iHigh(NULL,PERIOD_D1,iHighest(NULL,PERIOD_D1,MODE_HIGH,2,1));
   double weeklyHigh = iHigh(NULL,PERIOD_W1,iHighest(NULL,PERIOD_W1,MODE_HIGH,2,1));
   double monthlyHigh = iHigh(NULL,PERIOD_MN1,iHighest(NULL,PERIOD_MN1,MODE_HIGH,2,1));
   double dailyLow = iLow(NULL,PERIOD_D1,iHighest(NULL,PERIOD_D1,MODE_LOW,2,1));
   double weeklyLow = iLow(NULL,PERIOD_W1,iHighest(NULL,PERIOD_W1,MODE_LOW,2,1));
   double monthlyLow = iLow(NULL,PERIOD_MN1,iHighest(NULL,PERIOD_MN1,MODE_LOW,2,1));
   
  
   if (lastSignalLine>0 
      // && currentRisk(myMagic)<=0
      ) {
      if ( 
         CROSS_OVER_DAILY_HIGH_LONG &&
         (!filterUsingMA || (filterUsingMA && Ask < slowMA)) &&
         signalLine > dailyHigh &&
         lastSignalLine < dailyHigh) {
            PrintFormat("buy cross OVER daily high: d+=%.2f, d-=%.2f,w+=%.2f,w-=%.2f,m+=%.2f,m-=%.2f,signal=%.2f,lastSig=%.2f,slowMA=%.2f,fastMA=%.2f",dailyHigh,dailyLow,weeklyHigh,weeklyLow, monthlyHigh, monthlyLow, signalLine, lastSignalLine,slowMA,fastMA);
            openLongPosition(myMagic,lots(),Ask,Ask-initialStop,Ask+fixedTakeProfit, "cross over daily high");
      }
      if ( 
         CROSS_OVER_DAILY_LOW_LONG &&
         signalLine > dailyLow &&
         lastSignalLine < dailyLow) {
            PrintFormat("buy cross OVER daily low: d+=%.2f, d-=%.2f,w+=%.2f,w-=%.2f,m+=%.2f,m-=%.2f,signal=%.2f,lastSig=%.2f,slowMA=%.2f,fastMA=%.2f",dailyHigh,dailyLow,weeklyHigh,weeklyLow, monthlyHigh, monthlyLow, signalLine, lastSignalLine,slowMA,fastMA);
            openLongPosition(myMagic,lots(),Ask,Ask-initialStop,Ask+fixedTakeProfit, "cross over daily low");
      }
      
      if (
         CROSS_OVER_WEEKLY_HIGH_LONG && 
         signalLine > weeklyHigh && 
         lastSignalLine < weeklyHigh) {
            PrintFormat("buy cross OVER weekly high: d+=%.2f, d-=%.2f,w+=%.2f,w-=%.2f,m+=%.2f,m-=%.2f,signal=%.2f,lastSig=%.2f,slowMA=%.2f,fastMA=%.2f",dailyHigh,dailyLow,weeklyHigh,weeklyLow, monthlyHigh, monthlyLow, signalLine, lastSignalLine,slowMA,fastMA);
            openLongPosition(myMagic,lots(),Ask,Ask-initialStop,Ask+fixedTakeProfit, "cross over weekly high");
      }
      if (
         CROSS_OVER_WEEKLY_LOW_LONG &&
         signalLine > weeklyLow && 
         lastSignalLine < weeklyLow) {
            PrintFormat("buy cross OVER weekly low: d+=%.2f, d-=%.2f,w+=%.2f,w-=%.2f,m+=%.2f,m-=%.2f,signal=%.2f,lastSig=%.2f,slowMA=%.2f,fastMA=%.2f",dailyHigh,dailyLow,weeklyHigh,weeklyLow, monthlyHigh, monthlyLow, signalLine, lastSignalLine,slowMA,fastMA);
            openLongPosition(myMagic,lots(),Ask,Ask-initialStop,Ask+fixedTakeProfit, "cross over weekly low");
      }
      if (
         CROSS_OVER_MONTHLY_HIGH_LONG &&
         signalLine > monthlyHigh && 
         lastSignalLine < monthlyHigh) {
            PrintFormat("buy cross OVER monthly high: d+=%.2f, d-=%.2f,w+=%.2f,w-=%.2f,m+=%.2f,m-=%.2f,signal=%.2f,lastSig=%.2f,slowMA=%.2f,fastMA=%.2f",dailyHigh,dailyLow,weeklyHigh,weeklyLow, monthlyHigh, monthlyLow, signalLine, lastSignalLine,slowMA,fastMA);
            openLongPosition(myMagic,lots(),Ask,Ask-initialStop,Ask+fixedTakeProfit, "cross over monthly high");
      }
      
      if (
         CROSS_OVER_MONTHLY_LOW_LONG &&
         signalLine > monthlyLow && 
         lastSignalLine < monthlyLow) {
            PrintFormat("buy cross OVER monthly low: d+=%.2f, d-=%.2f,w+=%.2f,w-=%.2f,m+=%.2f,m-=%.2f,signal=%.2f,lastSig=%.2f,slowMA=%.2f,fastMA=%.2f",dailyHigh,dailyLow,weeklyHigh,weeklyLow, monthlyHigh, monthlyLow, signalLine, lastSignalLine,slowMA,fastMA);
            openLongPosition(myMagic,lots(),Ask,Ask-initialStop,Ask+fixedTakeProfit, "cross over monthly low");
      }
      
      //SHORT
      if ( 
         CROSS_UNDER_DAILY_HIGH_SHORT &&
         signalLine > dailyHigh &&
         lastSignalLine < dailyHigh) {
            PrintFormat("sell cross UNDER daily high: d+=%.2f, d-=%.2f,w+=%.2f,w-=%.2f,m+=%.2f,m-=%.2f,signal=%.2f,lastSig=%.2f,slowMA=%.2f,fastMA=%.2f",dailyHigh,dailyLow,weeklyHigh,weeklyLow, monthlyHigh, monthlyLow, signalLine, lastSignalLine,slowMA,fastMA);
            openShortPosition(myMagic,lots(),Bid,Bid+initialStop,Bid-fixedTakeProfit, "cross under daily high");
      }
      if ( 
         CROSS_UNDER_DAILY_LOW_SHORT &&
         (!filterUsingMA || (filterUsingMA && Bid > slowMA)) &&
         signalLine > dailyLow &&
         lastSignalLine < dailyLow) {
            PrintFormat("sell cross UNDER daily low: d+=%.2f, d-=%.2f,w+=%.2f,w-=%.2f,m+=%.2f,m-=%.2f,signal=%.2f,lastSig=%.2f,slowMA=%.2f,fastMA=%.2f",dailyHigh,dailyLow,weeklyHigh,weeklyLow, monthlyHigh, monthlyLow, signalLine, lastSignalLine,slowMA,fastMA);
            openShortPosition(myMagic,lots(),Bid,Bid+initialStop,Bid-fixedTakeProfit, "cross under daily low");
      }
      
      if (
         CROSS_UNDER_WEEKLY_HIGH_SHORT && 
         signalLine > weeklyHigh && 
         lastSignalLine < weeklyHigh) {
            PrintFormat("sell cross UNDER weekly high: d+=%.2f, d-=%.2f,w+=%.2f,w-=%.2f,m+=%.2f,m-=%.2f,signal=%.2f,lastSig=%.2f,slowMA=%.2f,fastMA=%.2f",dailyHigh,dailyLow,weeklyHigh,weeklyLow, monthlyHigh, monthlyLow, signalLine, lastSignalLine,slowMA,fastMA);
            openShortPosition(myMagic,lots(),Bid,Bid+initialStop,Bid-fixedTakeProfit, "cross under weekly high");
      }
      if (
         CROSS_UNDER_WEEKLY_LOW_SHORT &&
         signalLine > weeklyLow && 
         lastSignalLine < weeklyLow) {
            PrintFormat("sell cross UNDER weekly low: d+=%.2f, d-=%.2f,w+=%.2f,w-=%.2f,m+=%.2f,m-=%.2f,signal=%.2f,lastSig=%.2f,slowMA=%.2f,fastMA=%.2f",dailyHigh,dailyLow,weeklyHigh,weeklyLow, monthlyHigh, monthlyLow, signalLine, lastSignalLine,slowMA,fastMA);
            openShortPosition(myMagic,lots(),Bid,Bid+initialStop,Bid-fixedTakeProfit, "cross under weekly low");
      }
      if (
         CROSS_UNDER_MONTHLY_HIGH_SHORT &&
         (!filterUsingMA || (filterUsingMA && Bid > fastMA)) &&
         signalLine > monthlyHigh && 
         lastSignalLine < monthlyHigh) {
            PrintFormat("sell cross UNDER monthly high: d+=%.2f, d-=%.2f,w+=%.2f,w-=%.2f,m+=%.2f,m-=%.2f,signal=%.2f,lastSig=%.2f,slowMA=%.2f,fastMA=%.2f",dailyHigh,dailyLow,weeklyHigh,weeklyLow, monthlyHigh, monthlyLow, signalLine, lastSignalLine,slowMA,fastMA);
            openShortPosition(myMagic,lots(),Bid,Bid+initialStop,Bid-fixedTakeProfit, "cross under monthly high");
      }
      
      if (
         CROSS_UNDER_MONTHLY_LOW_SHORT &&
         (!filterUsingMA || (filterUsingMA && Bid < fastMA)) &&
         signalLine > monthlyLow && 
         lastSignalLine < monthlyLow) {
            PrintFormat("sell cross UNDER monthly low: d+=%.2f, d-=%.2f,w+=%.2f,w-=%.2f,m+=%.2f,m-=%.2f,signal=%.2f,lastSig=%.2f,slowMA=%.2f,fastMA=%.2f",dailyHigh,dailyLow,weeklyHigh,weeklyLow, monthlyHigh, monthlyLow, signalLine, lastSignalLine,slowMA,fastMA);
            openShortPosition(myMagic,lots(),Bid,Bid+initialStop,Bid-fixedTakeProfit, "cross under monthly low");
      }
   }
   
  }
//+------------------------------------------------------------------+

double lots() {
   double moneyToRisk = AccountFreeMargin()*riskInPercent/100;
   double pointsToRisk = initialStop;
   return (moneyToRisk / (pointsToRisk*MarketInfo(Symbol(),MODE_TICKVALUE)*10));
}
