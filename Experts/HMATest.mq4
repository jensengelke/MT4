//+------------------------------------------------------------------+
//|                                                      HMATest.mq4 |
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
extern int myMagic = 20161217;
extern double riskInPercent = 2;
extern double fixedTakeProfit = 0.0;
extern double initialStop = 60.0;
extern double stopAufEinstandBei = 5.0;
extern double trailInProfit = 30.0;
extern int period = 9;
extern int flatPeriod = 30;
extern double flatRange = 10.0;
extern double stdDevDist = 2.5;

static datetime lastTradeTime = NULL;

double hmaBuffer[];
int bufferPointer = 0;
bool bufferFilled = false;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
   ArrayResize(hmaBuffer,flatPeriod);
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
   
   if(lastTradeTime == Time[0]) {
      return;
   } else {
      lastTradeTime = Time[0];
   }
   
   trailInProfit(myMagic,trailInProfit);
   stopAufEinstand(myMagic,stopAufEinstandBei);
   
   hmaBuffer[bufferPointer]=iCustom(Symbol(),PERIOD_CURRENT,"AllAverages",0,0,period,0,8,0,0);
   bufferPointer++;
   if (bufferPointer >= flatPeriod) {
      bufferPointer = 0;
      bufferFilled = true;
   }

   if (!bufferFilled) return;
   int maxIndex = ArrayMaximum(hmaBuffer,WHOLE_ARRAY,0);
   int minIndex = ArrayMinimum(hmaBuffer,WHOLE_ARRAY,0);
   
   double hmaRange = hmaBuffer[maxIndex] - hmaBuffer[minIndex];
   double stdDev = iStdDev(Symbol(),PERIOD_CURRENT,period,0,MODE_SMA,PRICE_CLOSE,0);
   if (hmaRange<flatRange) {
     // Print("flat");
      int i = bufferPointer - 1;
      if (i<0) i=flatPeriod-1;
     // PrintFormat("High=%.2f, hmaBuffer=%.2f, stdDev=%.2f, trigger=%.2f",High[1],hmaBuffer[i],stdDev,(hmaBuffer[i]+stdDevDist*stdDev));
      double upperBand = hmaBuffer[i] + stdDevDist*stdDev;
      if (High[1] > upperBand && Bid < upperBand) {
         closeLongPositions(myMagic);
         if (currentRisk(myMagic)<=0) {
            double stop=High[1];
            double tp=Bid-(stdDev*stdDevDist);
            openShortPosition(myMagic,lotsByRiskFreeMargin(riskInPercent,Bid+stop),Bid,stop,tp);
         }
      }
      double lowerBand = hmaBuffer[i] - stdDevDist*stdDev;
      if (Low[1] < lowerBand && Ask > lowerBand) {
         closeShortPositions(myMagic);
         if (currentRisk(myMagic)<=0) {
            double stop=Low[1];
            double tp=Ask+(stdDev*stdDevDist);
            openLongPosition(myMagic,lotsByRiskFreeMargin(riskInPercent,Ask-stop),Ask,stop, tp);                        
         }
      }
   }
    
   
   

  }
//+------------------------------------------------------------------+

double lots() {
   double moneyToRisk = AccountFreeMargin()*riskInPercent/100;
   double pointsToRisk = initialStop;
   double lots = (moneyToRisk / (pointsToRisk*MarketInfo(Symbol(),MODE_TICKVALUE)*10));
   if (lots>MarketInfo(Symbol(),MODE_MAXLOT)) return MarketInfo(Symbol(),MODE_MAXLOT);   
   return lots;
}
