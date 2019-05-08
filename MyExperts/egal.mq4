//+------------------------------------------------------------------+
//|                                                         egal.mq4 |
//|                                                             egal |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "egal"
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

input int    myMagic = 20190413;
input double quietMaxAdx = 20.0;
input int    quietMAPeriod = 32;
input double rsiThreshold = 10.0;
input int    rsiPeriod = 2;

input double emergencyStop = 100.0;
input double target = 10.0;
input int    newPosOnlyAfter = 8;
input int    newPosOnlyBefore = 21;

input int    maxPos = 1.0;
input double maxPosSize = 1.0;
input bool   unbiased = false;

input int    tracelevel = 2;

datetime lastTradeTime = NULL;
double lots = 0.0;
double minRSI;
double maxRSI;
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
   lots = NormalizeDouble(maxPosSize /maxPos, 1); //TODO: LOTSTEP 
   minRSI = rsiThreshold;
   maxRSI = 100 - rsiThreshold;
   
   PrintFormat("lots: %.5f, minRSI: %.5f, maxRSI: %.5f", lots,minRSI,maxRSI);
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
   if (Time[0] == lastTradeTime) return;   
   lastTradeTime = Time[0];   
   
   if (isQuiet() && TimeHour(TimeLocal())>=newPosOnlyAfter && TimeHour(TimeLocal())<=newPosOnlyBefore) {
   
   
      //entry timing
      double rsi = iRSI(_Symbol,PERIOD_CURRENT,rsiPeriod,PRICE_CLOSE,1);
      if (tracelevel > 1) PrintFormat("rsi: %.5f", rsi);
      if (!unbiased && (rsi > minRSI) && (rsi < maxRSI)) return;
      
      double pointsToRecoverLong = 0.0;
      double pointsToRecoverShort = 0.0;
      int    numberOfLongs = 0;
      int    numberOfShorts = 0;
      for (int i=OrdersTotal();i>=0;i--) {
         if (OrderSelect(i,SELECT_BY_POS)) {
            if (OrderMagicNumber() != myMagic) continue;
            if (OrderType() == OP_SELL) {
               pointsToRecoverShort += (Bid - OrderOpenPrice());
               numberOfShorts++;
            }
            if (OrderType() == OP_BUY) {
               pointsToRecoverLong += (OrderOpenPrice() - Ask);
               numberOfLongs++;
            }
         }      
      }
      
      if (tracelevel>0) {
         PrintFormat("number of long: %i, to recover long: %.5f, number of short: %i, to recover short: %.5f", 
          numberOfLongs,
          pointsToRecoverLong,
          numberOfShorts,
          pointsToRecoverShort);
      }
      
      double stop; 
      double tp;
      
      
      if (rsi<minRSI || unbiased) {
      
         stop = NormalizeDouble(Ask - emergencyStop,_Digits);
         tp   = NormalizeDouble(Ask + target,_Digits);
         if (pointsToRecoverLong>0.0 && (numberOfLongs < maxPos)) {
            tp += pointsToRecoverLong / ++numberOfLongs;
         }
         
         if (tracelevel>0) {
            PrintFormat("Long: ask:%.5f, stop: %.5f, tp: %.5f, lots: %.5f", Ask,stop,tp,lots);
         }
         
         if (numberOfLongs<=maxPos) {
            if (!OrderSend(_Symbol,OP_BUY,lots, Ask,250, stop, tp,NULL, myMagic,0,clrGreen)) {
               Print("E0001");
            }
         }
      }
      
      if (rsi > maxRSI || unbiased) {
         
         stop = NormalizeDouble(Bid + emergencyStop, _Digits);
         tp   = NormalizeDouble(Bid - target, _Digits);
      
         if (pointsToRecoverShort>0.0 && (numberOfShorts < maxPos)) {
            tp -= pointsToRecoverShort / ++numberOfShorts;
         }
         
         if (tracelevel>0) {
            PrintFormat("Short: Bid:%.5f, stop: %.5f, tp: %.5f, lots: %.5f", Bid,stop,tp,lots);
         }
         
         if (numberOfShorts<=maxPos) {
            if (!OrderSend(_Symbol,OP_SELL,lots, Bid,250, stop, tp,NULL, myMagic,0,clrRed)) {
               PrintFormat("E0002");
            }
         }
      }
   }
   
  }
//+------------------------------------------------------------------+


bool isQuiet() {
   bool quiet = false;
   double adx = iADX(_Symbol,PERIOD_CURRENT,quietMAPeriod,PRICE_CLOSE,MODE_MAIN,1);
   
   quiet = adx < quietMaxAdx;
   return quiet;
   
}