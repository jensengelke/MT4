//+------------------------------------------------------------------+
//|                                                     fractals.mq4 |
//|                                                center of gravity |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "center of gravity"
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

#include "../Include/JensUtils.mqh";


extern string startTime = "08:00";
extern string endTime = "21:58";
extern int myMagic = 201700430;
extern double stopAufEinstandBei = 10.0;
extern double riskInPercent = 0.5;
extern double trailInProfit = 30.0;
extern double minDistanceBetweenOrders = 10.0;
extern int rsiPeriod = 48;
extern int atrPeriod = 48;
extern double atrFactorForInitialStop = 1.7;
extern double fixedTakeProfit = 0.0;

extern bool trace = false;

static int lastMinutes = -1;
static int pendingLongTicket = 0;
static int pendingShortTicket = 0;



//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- create timer
   EventSetTimer(60);
      
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
   stopAufEinstand(myMagic,stopAufEinstandBei);
   
   
   
   //act only if we don't have pending orders
   bool pendingLongOrderMissing = false;
   bool pendingShortOrderMissing = false;
   
   if (pendingLongTicket == 0) {
      pendingLongOrderMissing = true;
   } else {
      OrderSelect(pendingLongTicket,SELECT_BY_TICKET,MODE_TRADES);
      if (OP_BUYSTOP != OrderType()) { pendingLongOrderMissing = true; }
   }
   
   if (pendingShortTicket == 0) {
      pendingShortOrderMissing = true;
   } else {
     OrderSelect(pendingShortTicket,SELECT_BY_TICKET,MODE_TRADES);
      if (OP_SELLSTOP != OrderType()) { pendingShortOrderMissing = true; }
   }
   //dynamicity filter
   //RSI nicht zwischen 40 und 60
   
   double rsi = iRSI(Symbol(),PERIOD_CURRENT,rsiPeriod,PRICE_CLOSE,0);
   if (40 > rsi && 60 < rsi) {
      return;
   }
   
   //directional bias
   //aligator entwirrt
   double jaw = iAlligator(Symbol(),PERIOD_CURRENT,13,8,8,5,5,3,MODE_SMA,PRICE_MEDIAN,MODE_GATORJAW,8);
   double teeth = iAlligator(Symbol(),PERIOD_CURRENT,13,8,8,5,5,3,MODE_SMA,PRICE_MEDIAN,MODE_GATORTEETH,5);
   double lips = iAlligator(Symbol(),PERIOD_CURRENT,13,8,8,5,5,3,MODE_SMA,PRICE_MEDIAN,MODE_GATORLIPS,3);
   
   int bias = 0;
   if ( jaw > teeth && teeth > lips) {
      bias = -1;
   }
   
   if ( jaw < teeth && teeth < lips) {
      bias = 1;
   }
   
   if (0 == bias) {
      return;
   }
   
   double highForPendingOrder = -1.0;
   double lowForPendingOrder = -1.0; 
   
   //determine trigger prices
   if (pendingLongOrderMissing || pendingShortOrderMissing) {

      int barsConsidered = 1;
      do {
         if (pendingLongOrderMissing && highForPendingOrder == -1.0) {
            double fractalUpper = iFractals(Symbol(),PERIOD_CURRENT,MODE_UPPER,barsConsidered);
            if (fractalUpper > 0 && trace) {
               PrintFormat("inspecting high: %.2f when Ask=%.2f",fractalUpper,Ask);
            }
            if (fractalUpper > Ask && !orderExists(myMagic,1,fractalUpper, minDistanceBetweenOrders)) {
               highForPendingOrder = fractalUpper;
            }
         }
         
         if (pendingShortOrderMissing && lowForPendingOrder == -1.0) {
            double fractalLower = iFractals(Symbol(),PERIOD_CURRENT,MODE_LOWER,barsConsidered);
            if (fractalLower < Bid && fractalLower > 0 && !orderExists(myMagic,-1,fractalLower, minDistanceBetweenOrders)) {
               lowForPendingOrder = fractalLower;
            }
         }
         barsConsidered++;
      } while ( barsConsidered <1000 && 
        ( (pendingLongOrderMissing && highForPendingOrder == -1.0) || 
           (pendingShortOrderMissing && lowForPendingOrder == -1.0) 
        ));
      if (trace) {
        PrintFormat("determined trigger prices after bars=%i: high=%.2f, low=%.2f", barsConsidered,highForPendingOrder, lowForPendingOrder);
      }
   }
   
   
   
   double stopDistance = iATR(Symbol(),PERIOD_CURRENT,atrPeriod,0) * atrFactorForInitialStop;
   double lots = lotsByRisk(stopDistance,riskInPercent/100,1);
   
   //create orders
   if (pendingLongOrderMissing && bias == 1 && highForPendingOrder != -1.0) {
      double price = highForPendingOrder;
      double stop = price - stopDistance;
      double tp = 0;
      if (fixedTakeProfit > 0.0) {
         tp = price + fixedTakeProfit;
      }
      if (trace) {
         PrintFormat("Opening buy stop: Ask=%.2f, lots=%.2f, price=%.2f, stop=%.2f, tp =%.2f", Ask,lots,price,stop,tp);
      }
      OrderSend(Symbol(),OP_BUYSTOP,lots,price,3, stop,tp,"swing up",myMagic,0,clrGreen);
   }
   
   if (pendingShortOrderMissing && bias == -1 && lowForPendingOrder != -1.0) {
      double price = lowForPendingOrder;
      double stop = price + stopDistance;
      double tp = 0;
      if (fixedTakeProfit > 0.0) {
         tp = price - fixedTakeProfit;
      }
      if (trace) {
         PrintFormat("Opening sell stop: Bid=%.2f, lots=%.2f, price=%.2f, stop=%.2f, tp =%.2f", Bid,lots,price,stop,tp);
      }
      OrderSend(Symbol(),OP_SELLSTOP,lots,price,3, stop,tp,"swing down",myMagic,0,clrGreen);
   }
   
  }
//+------------------------------------------------------------------+
//| Timer function                                                   |
//+------------------------------------------------------------------+
void OnTimer()
  {
   if (!isHandelszeit(startTime,endTime)) {
         closeAllPendingOrders(myMagic);
         closeAllOpenOrders(myMagic);
      return;
   }
   
  }
//+------------------------------------------------------------------+
