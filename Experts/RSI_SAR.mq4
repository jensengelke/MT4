//+------------------------------------------------------------------+
//|                                                      RSI_SAR.mq4 |
//|                                                          RSI_RSA |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "RSI_RSA"
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

#include "../Include/JensUtils.mqh";


extern string startTime = "00:00";
extern string endTime = "21:58";
extern int myMagic = 20171030;
extern double riskInPercent = 1.0;
extern int maxPos = 3;
extern int rsiPeriod = 2;
extern double rsiHigh = 70.0;
extern double rsiLow = 30.0;
extern double sarStep = 0.02;
extern double sarMax = 0.2;
extern int trace = 0;
extern double buffer = 10.0;
extern double minStop = 20.0;

extern int smaFilterPeriod = 44;
extern double smaFilterMinMove = 50.0;
extern int smaFilterLookback = 44;


static datetime lastTradeTime = NULL;
static int symbolDigits = -1;
static int lotDigits = -1;






//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
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
   
   double sar = iSAR(Symbol(),PERIOD_CURRENT,sarStep,sarMax,0);
   double rsi = iRSI(Symbol(),PERIOD_CURRENT,rsiPeriod,PRICE_CLOSE,0);
   double rsiPrev = iRSI(Symbol(),PERIOD_CURRENT,rsiPeriod,PRICE_CLOSE,1);
   
   double sma = iMA(Symbol(),PERIOD_CURRENT,smaFilterPeriod,0,MODE_SMA,PRICE_CLOSE,0);
   double smaShift = iMA(Symbol(),PERIOD_CURRENT,smaFilterPeriod,0,MODE_SMA,PRICE_CLOSE,smaFilterLookback);
   
   bool smaFilter = MathAbs(sma-smaShift) > smaFilterMinMove;
   if (smaFilterPeriod == 0) 
      smaFilter = true;
   
   int openOrders = countOpenPositions(myMagic);
   //TODO: minStop?
   trail(myMagic,sar,sar,false);
   
   
   if (trace>2) {
     if (rsi<rsiLow)
      PrintFormat("sar=%.2f,rsi=%.2f,rsiPrev=%.2f, close0=%.2f,close1=%.2f",sar,rsi,rsiPrev,Close[0],Close[1]);
   }
   
   if (smaFilter &&
      openOrders < maxPos &&
      countOpenPendingOrders(myMagic) == 0 &&
      currentRisk(myMagic)<=0 &&
      currentDirectionOfOpenPositions(myMagic) >=0 &&
      rsi > rsiPrev &&
      rsiPrev < rsiLow &&
      sma > smaShift &&
      Close[0] > sar 
      
   ) {
      if (Close[0] < Close[1]) {
         double price = MathMax((Close[0]+buffer), (Close[1]+buffer));
         double stop = sar;
         if (MathAbs(price-stop)<minStop) {
            PrintFormat("changed stop: %.2f new: %.2f (price: %.2f)",stop, (price-minStop),price);
            stop = price-minStop;
         }
         double lots = lotsByRisk( MathAbs(price-stop),riskInPercent,lotDigits);
         if (trace>0) {
            PrintFormat("buy stop: lots=%.2f, price=%.2f, stop=%.2f, Ask=%.2f",lots,price,stop,Ask);
         }
         if (trace>1) {
            PrintFormat("close0=%.2f,Close1=%.2f,price=%.2f",Close[0],Close[1],price);
         }
         OrderSend(Symbol(),OP_BUYSTOP,lots,price,5,stop,0,"signal long",myMagic, 3600*24*7,clrGreen);
      } else {
         double price = Ask;
         double stop = sar;
         if (MathAbs(price-stop)<minStop) {
            PrintFormat("changed stop: %.2f new: %.2f (price: %.2f)",stop, (price-minStop),price);
            stop = price-minStop;
         }
         double lots = lotsByRisk( MathAbs(price-stop),riskInPercent,lotDigits);
         if (trace>0) {
            PrintFormat("buy: lots=%.2f, price=%.2f, stop=%.2f, Ask=%.2f",lots,price,stop,Ask);
         }
         if (trace>1) {
            PrintFormat("close0=%.2f,Close1=%.2f,price=%.2f",Close[0],Close[1],price);
         }
         OrderSend(Symbol(),OP_BUY,lots,price,5,stop,0,"signal long2", myMagic,0,clrGreen);
      }
   }
   
   if (
      smaFilter &&
      openOrders < maxPos &&
      countOpenPendingOrders(myMagic) == 0 &&
      rsi < rsiPrev &&
      rsiPrev > rsiHigh &&
      Close[0] < sar &&
      currentRisk(myMagic)<=0 &&
      sma < smaShift &&
      currentDirectionOfOpenPositions(myMagic) <=0 
   ) {
      if (Close[0] > Close[1]) {
         double price = MathMin((Close[0]-buffer), (Close[1]-buffer));
         double stop = sar;
         if (MathAbs(price-stop)<minStop) {
            PrintFormat("changed stop: %.2f new: %2f (price: %.2f)",stop, (price+minStop),price);
            stop = price+minStop;
         }
         double lots = lotsByRisk( MathAbs(stop-price),riskInPercent,lotDigits);
         if (trace>0) {
            PrintFormat("sell stop: lots=%.2f, price=%.2f, stop=%.2f, Bid=%.2f",lots,price,stop,Bid);
         }
         if (trace>1) {
            PrintFormat("close0=%.2f,Close1=%.2f,price=%.2f",Close[0],Close[1],price);
         }
         OrderSend(Symbol(),OP_SELLSTOP,lots,price,5,stop,0,"signal short",myMagic, 3600*24*7,clrGreen);
      } else {
         double price = Bid;
         double stop = sar;
         if (MathAbs(price-stop)<minStop) {
            PrintFormat("changed stop: %.2f new: %.2f (price: %.2f)",stop, (price+minStop),price);
            stop = price+minStop;
         }
         double lots = lotsByRisk( MathAbs(stop-price),riskInPercent,lotDigits);
         if (trace>0) {
            PrintFormat("sell stop: lots=%.2f, price=%.2f, stop=%.2f, Bid=%.2f",lots,price,stop,Bid);
         }
         if (trace>1) {
            PrintFormat("close0=%.2f,Close1=%.2f,price=%.2f",Close[0],Close[1],price);
         }
         OrderSend(Symbol(),OP_SELL,lots,price,5,stop,0,"signal short2", myMagic,0,clrGreen);
      }
   }
   
   
   
  }
//+------------------------------------------------------------------+
