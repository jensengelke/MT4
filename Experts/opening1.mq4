//+------------------------------------------------------------------+
//|                                                     opening1.mq4 |
//|                                                         opening1 |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "opening1"
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

#include "../Include/JensUtils.mqh";

extern int openRangeEndHour = 10;
extern int openRangeEndMinute = 15;
extern int flatAfterHour = 21;
extern int flatAfterMinute = 45;
extern double riskInPercent = 1.0;
extern int myMagic = 201700625;
extern double buffer = 10.0;
extern double trailInProfit = 20.0;
extern double takeProfit = 80.0;
extern double maxAmplitude = 50.0;
extern double rangeDistance = 0.2;
extern bool debug = false;

int lotDigits = -1;

static double openHigh = 0.0;
static double openLow = 0.0;

static datetime lastTradeTime = NULL;
static int lastTradeDay = -1;

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
//---
   if (Time[0] == lastTradeTime) {
      return;
   }
   lastTradeTime = Time[0];
   
   trailInProfit(myMagic,trailInProfit);

   int minute = TimeMinute(TimeLocal());
   int hour = TimeHour(TimeLocal());

   if (hour<openRangeEndHour) {
      return;
   }
      
   if (hour == flatAfterHour && minute >= flatAfterMinute) {
      closeAllOpenOrders(myMagic);
      closeAllPendingOrders(myMagic);
      openHigh = 0.0;
      openLow = 0.0;  
      return;
   }
   
   if (hour==openRangeEndHour && minute >= openRangeEndMinute && openHigh == 0.0) {
      openHigh = iHigh(Symbol(),PERIOD_D1,0);
      openLow = iLow(Symbol(),PERIOD_D1,0);
      if (debug) {
         PrintFormat("openHigh=%.2f,openLow=%.2f",openHigh,openLow);
      }
   }
   
   if (OrdersTotal()==0 && openHigh!=0.0 && lastTradeDay != Day()) {
      lastTradeDay = Day();
      double amplitude = openHigh - openLow;
      if (amplitude < maxAmplitude) {
         if (Ask < (openLow+ rangeDistance*amplitude) && Ask > openLow) {
            double stop = NormalizeDouble(openLow - buffer, lotDigits);
            double lots = lotsByRisk(Ask-stop,riskInPercent,lotDigits);            
            double tp = NormalizeDouble(openHigh,lotDigits);;
            if (takeProfit != 0.0)  { tp =  Ask + takeProfit; }
            PrintFormat(" buy: openLow=%.2f, stop=%.2f,tp=%.2f,lots=%.2f,lastClose=%.2f",openLow,stop,tp,lots,Close[0]);
            OrderSend(Symbol(),OP_BUY,lots,Ask,3,stop,tp,NULL,myMagic,0,clrGreen);
         }  
         if (Bid > (openHigh - rangeDistance*amplitude) && Bid < openHigh) {
            double stop = NormalizeDouble(openHigh + buffer,lotDigits);
            double lots = lotsByRisk(stop-Bid,riskInPercent,lotDigits);            
            double tp = NormalizeDouble(openLow,lotDigits);
            if (takeProfit != 0.0) { tp = Bid - takeProfit; }
            PrintFormat(" sell: openHigh=%.2f, stop=%.2f,tp=%.2f,lots=%.2f,lastClose=%.2f",openHigh,stop,tp,lots,Close[0]);
            OrderSend(Symbol(),OP_SELL,lots,Bid,3,stop,tp,NULL,myMagic,0,clrGreen);
         }
         
         if (OrdersTotal()==0) {
            double stop = NormalizeDouble(openLow - buffer,lotDigits);
            double price = NormalizeDouble(openLow+(rangeDistance*amplitude),lotDigits);
            double tp = NormalizeDouble(openHigh,lotDigits);
            if (takeProfit!=0) {
               tp = price + takeProfit;
            }
            double lots = lotsByRisk(rangeDistance*amplitude,riskInPercent,lotDigits);
            if (debug) {
               PrintFormat("pending buy: openLow=%.2f, stop=%.2f,tp=%.2f,lots=%.2f,lastClose=%.2f",openLow,stop,tp,lots,Close[0]);
            }
            OrderSend(Symbol(),OP_BUYLIMIT, lots, price ,3,stop,tp,NULL,myMagic,0,clrGreen);
            stop = NormalizeDouble(openHigh + buffer,lotDigits);
            price = NormalizeDouble(openHigh-rangeDistance*amplitude,lotDigits);
            tp = NormalizeDouble(openLow,lotDigits);
            if (takeProfit != 0.0) { tp = price-takeProfit;}
            if (debug) {
               PrintFormat("pending sell: openHigh=%.2f, stop=%.2f,tp=%.2f,lots=%.2f,lastClose=%.2f",openHigh,stop,tp,lots,Close[0]);
            }
            OrderSend(Symbol(),OP_SELLLIMIT,lots,price,3,stop,tp,NULL,myMagic,0,clrGreen);
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
