//+------------------------------------------------------------------+
//|                                                     system11.mq4 |
//|                                                         aligator |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "MA direction"
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict


#include "../Include/JensUtils.mqh";

extern string startTime = "08:00";
extern string endTime = "21:58";
extern int myMagic = 20161217;
extern double baseLots = 1.0;
extern double accountSize = 1000.0;
extern double fixedTakeProfit = 0.0;
extern double initialStop = 60.0;
extern double stopAufEinstandBei = 5.0;
extern int stdDev_period = 200;
extern double stdDev_threshold = 7.0;
extern double trailInProfit = 30.0;
extern int max_open_pos = 4;
extern double min_ma_roc_in_percent = 0.1;

string screenString = "StatusWindow";
static datetime lastTradeTime = NULL;

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
         closeAllPendingOrders(myMagic);
         closeAllOpenOrders(myMagic);
      return;
   }
   
   
   
   trailInProfit(myMagic,trailInProfit);
   stopAufEinstand(myMagic,stopAufEinstandBei);
   if(lastTradeTime == Time[0]) {
      return;
   } else {
      lastTradeTime = Time[0];
   }
   
   double standardDeviation =iStdDev(NULL,PERIOD_CURRENT,stdDev_period,0,MODE_SMA,PRICE_CLOSE,0);
   double maCurrent = iMA(NULL,PERIOD_CURRENT,stdDev_period,0,MODE_SMA,PRICE_CLOSE,0);
   double maPrev = iMA(NULL,PERIOD_CURRENT,stdDev_period,0,MODE_SMA,PRICE_CLOSE,1);
   double maRoc = maCurrent / maPrev;
   
  if (
      currentRisk(myMagic) <=0 &&
      OrdersTotal() < max_open_pos &&
      standardDeviation > stdDev_threshold 
   ){
      if (maCurrent > maPrev && maRoc > (1+0.01*min_ma_roc_in_percent)) {
         openLongPosition();
      } else if (maCurrent < maPrev && maRoc < (1-0.01*min_ma_roc_in_percent)) {
         openShortPosition();
      }
   }
   
   
     
}
//+------------------------------------------------------------------+
void openLongPosition() {
   OrderSend(NULL,OP_BUY,lots(baseLots,accountSize),Ask,3,Ask - initialStop,0,NULL,myMagic,0,clrGreen);
}

void openShortPosition() {
   OrderSend(NULL,OP_SELL,lots(baseLots,accountSize),Bid ,3,Bid+initialStop,0,NULL,myMagic,0,clrGreen);
}
