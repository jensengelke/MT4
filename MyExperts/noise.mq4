//+------------------------------------------------------------------+
//|                                                        noise.mq4 |
//|                                                            Noise |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Noise"
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict
#include "../../Include/MyInclude/JensUtils.mqh";
extern int myMagic = 20180318;

extern int tracelevel = 2;
//extern int ext_adxPeriod = 12;
//extern double ext_maxAdx  =45.0;
extern int ext_atrPeriod = 12;
extern double ext_minATR = 50.0;
extern double ext_bodySize = 0.7;
extern double ext_atrFactorProfit = 0.4;
extern double ext_atrFactorStop = 1.0;
extern double  ext_closeToExtreme = 0.1;
extern double ext_adxPeriod=10;
extern double ext_maxAdx=30;

extern double risk = 1;

static datetime lastTradeTime = NULL;
static int lotDigits = 5;

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
   if (Time[0] ==lastTradeTime) return;
   lastTradeTime = Time[0];   
   
  // bool candleTrend = (Close[1]>Open[1]) & (Close[2]>Open[2]) & (Close[3] > Open[3]) ) | 
    //                           ((Close[1]<Open[1]) & (Close[2]<Open[2]) & (Close[3] < Open[3]));

   bool adxTrend = iADX(Symbol(), PERIOD_CURRENT,ext_adxPeriod,PRICE_CLOSE,  MODE_MAIN,0) >ext_maxAdx;
   
   if (//candleTrend 
        adxTrend
        ) return;
   
   
   double candleBody = MathAbs(Close[1]-Open[1]);
   double candleSize = High[1]-Low[1];
   bool closeToTop = (Close[1] > ( High[1] - ext_closeToExtreme*candleSize));
   bool closeToBottom =  (Close[1] < (Low[1]+ ext_closeToExtreme*candleSize));
      
      
   trailInProfit(myMagic,20);
      
   bool buy=false;
   bool sell=false;
   PrintFormat("candleSize: %.5f",candleSize);
   if  (candleSize > 0.00001 & 
      ext_bodySize > (candleBody / candleSize)) {  //Kerzenkörper zu Kerzengröße als Maß von Noise
      if ( closeToTop) {
         buy = true;
      } else if (closeToBottom) { // hat nah am Rand geschlossen ist wie Trend
        sell = true;
      } else {
        buy = true;
        sell = true;
      }
       
   }
   
   if (buy|sell) {
      double atr = iATR(Symbol(),PERIOD_CURRENT,ext_atrPeriod,0);
      if (atr > ext_minATR) {
            if (buy & countOpenLongPositions(myMagic) == 0) {
               double target = Ask + (ext_atrFactorProfit * atr);
               double stop = Bid - ( ext_atrFactorStop * atr);
               double lots = lotsByRisk(Ask-stop,risk,1);
               buyImmediately(lots,stop,target);
            }
            
            if (sell & countOpenShortPositions(myMagic) == 0) {
               double target = Bid - (ext_atrFactorProfit * atr);
               double stop = Ask + ( ext_atrFactorStop * atr);
               double lots = lotsByRisk(stop-Bid,risk,1);
               sellImmediately(lots,stop,target);
            }
          }
     }
   
  }
//+------------------------------------------------------------------+

void buyImmediately(double lots, double stop, double profit) {
   PrintFormat("BUY Ask=%5f, stop=%5f, tp=%5f",Ask,stop,profit);
   OrderSend(Symbol(),OP_BUY,lots,Ask,5,stop,profit,"noise_" + myMagic,myMagic,0,clrGreen);
}

void sellImmediately(double lots, double stop, double profit) {
  PrintFormat("Sell Bid=%5f, stop=%5f, tp=%5f",Bid,stop,profit);
  OrderSend(Symbol(),OP_SELL,lots,Bid,5,stop,profit,"noise_"+myMagic,myMagic,0,clrRed);
}
