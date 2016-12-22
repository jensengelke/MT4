//+------------------------------------------------------------------+
//|                                                      system8.mq4 |
//|                                      ein bisschen was geht immer |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "ein bisschen was geht immer"
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

#include "../Include/JensUtils.mqh";

extern int startHour = 8;
extern int startMinute = 0;
extern int endHour = 21;
extern int endMinute = 58;
extern int myMagic = 20161124;
extern double baseLots = 1.0;
extern double accountSize = 1000.0;
extern double range = 30.0;
extern int rangePeriod = 60;
extern double minRange = 10;
extern double stop = 5.0;
extern double tp = 2.0;
extern double maxOrders = 4;
extern double stopAufEinstandBei = 10.0;
extern double trailInProfit = 0.0;
extern int trailWithLastXCandle = 0;

datetime lastTradeTime = NULL;
int longTicket = 0;
int shortTicket = 0;

string screenString = "StatusWindow";
string screenRect = "Range";

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
   if (!isHandelszeit(startHour,startMinute,endHour,endMinute)) {
         closeAllPendingOrders(myMagic);
         closeAllOpenOrders(myMagic);
      return;
   }
   stopAufEinstand(myMagic,stopAufEinstandBei);
   if (trailInProfit > 0) {
      trailInProfit(myMagic,trailInProfit);
   } 
   
   if(lastTradeTime == Time[0]) {
     return;
   } else {
      lastTradeTime = Time[0];
   }
   
   if (trailWithLastXCandle>0) {
   trailWithLastXCandle(myMagic,trailWithLastXCandle);
  }
   
   double lowestLow = Low[iLowest(NULL,PERIOD_CURRENT,MODE_LOW,rangePeriod,0)];
   double highestHigh = High[iHighest(NULL,PERIOD_CURRENT,MODE_HIGH,rangePeriod,0)];
   double spread = Ask - Bid;
   
   string status = StringFormat("actual range=%.2f (target=%.2f)", (highestHigh-lowestLow),range); 
   
   ObjectDelete(screenString);
   ObjectDelete(screenRect);
   ObjectCreate(screenString, OBJ_LABEL, 0, 0, 0);
   ObjectSetText(screenString,status, 8, "Arial Bold", clrRed);
   
   ObjectSet(screenString, OBJPROP_CORNER, 3);
   ObjectSet(screenString, OBJPROP_XDISTANCE, 10);
   ObjectSet(screenString, OBJPROP_YDISTANCE, 10); 
   
   ObjectCreate(screenRect, OBJ_RECTANGLE, 0,TimeCurrent()-60*rangePeriod*Period(),highestHigh,TimeCurrent(),lowestLow);
   ObjectSet(screenRect, OBJPROP_BACK, true);
   ObjectSet(screenRect, OBJPROP_COLOR, clrBlue);
   ObjectSet(screenRect, OBJPROP_STYLE, STYLE_SOLID);
   
     
   if (OrdersTotal()<maxOrders && (highestHigh-lowestLow)<=range && minRange<(highestHigh-lowestLow)) {
      if (countOpenPositions(myMagic,OP_BUY)<maxOrders/2 && Ask < lowestLow+(range/5)) {
         double stopLoss=Ask-stop;
         if (stopLoss > lowestLow){ stop = lowestLow; }
         openLongPosition(myMagic,lots(baseLots, accountSize), Ask, stopLoss, Ask+tp+spread) ;
      }
      if (countOpenPositions(myMagic,OP_SELL)<maxOrders/2 && Bid > (highestHigh-range/5) ) {
         double stopLoss=Bid+stop;
         if (stopLoss < highestHigh){ stopLoss = highestHigh; }
         openShortPosition(myMagic,lots(baseLots, accountSize), Bid, stopLoss, Bid-spread-tp) ;
      }
   }   
  }
//+------------------------------------------------------------------+
