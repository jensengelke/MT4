
//+------------------------------------------------------------------+
//|                                                      system9.mq4 |
//|                                                SMA open vs close |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "two EMAs"
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

#include "../Include/JensUtils.mqh";

extern string startTime = "08:00";
extern string endTime = "21:58";
extern int myMagic = 20161127;
extern double baseLots = 1.0;
extern double accountSize = 1000.0;
extern double fixedTakeProfit = 0.0;
extern double initialStop = 60.0;
extern double stopAufEinstandBei = 5.0;
extern int emaPeriodSlow = 40;
extern int emaPeriodFast = 7;
extern double steil = 0.03;

string screenString = "StatusWindow";
double maxAcc = 1;
double minAcc = 1;

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
   
   double slowEMA = iMA(NULL,PERIOD_CURRENT,emaPeriodSlow,0,MODE_EMA,PRICE_CLOSE,0);
   double slowEMAPrev = iMA(NULL,PERIOD_CURRENT,emaPeriodSlow,0,MODE_EMA,PRICE_CLOSE,1);
   
   double fastEMA = iMA(NULL,PERIOD_CURRENT,emaPeriodFast,0,MODE_EMA,PRICE_CLOSE,0);
   double fastEMAPrev = iMA(NULL,PERIOD_CURRENT,emaPeriodFast,0,MODE_EMA,PRICE_CLOSE,1);
   
   double spread = MathAbs(Bid-Ask);
   
   double accelerator = fastEMA / fastEMAPrev;
   
   if (accelerator>maxAcc) {
      maxAcc = accelerator;
   }
   if (accelerator<minAcc) {
      minAcc = accelerator;
   }
   string comment = StringFormat("current=%.8f, min=%.8f, max=%.8f",accelerator,minAcc,maxAcc);
   Comment(comment);
      
   int direction = currentDirectionOfOpenPositions(myMagic);
   
   if (  slowEMA > fastEMA && 
         slowEMAPrev > fastEMAPrev &&
         fastEMA < fastEMAPrev &&
         slowEMA < slowEMAPrev         
         ) { //downtrend
      if (direction > 0) {
         closeLongPositions(myMagic);
      }
      
      if (currentRisk(myMagic)<=0 && Bid < fastEMA) {      
         openShortPosition();
      }
   } 
   
   if (  slowEMA < fastEMA && 
         slowEMAPrev < fastEMAPrev &&
         slowEMA > slowEMAPrev &&
         fastEMA > fastEMAPrev) { //uptrend
      if (direction < 0) {
         closeShortPositions(myMagic);
      }
      if (currentRisk(myMagic)<=0 && Ask > fastEMA) {
         openLongPosition();
      }
   }
   
   if (stopAufEinstandBei >0) {
      for (int i=OrdersTotal();i>=0;i--) {
         if (OrderMagicNumber() != myMagic) {continue;}
         if (OrderSymbol() != Symbol()) {continue;}
         if (OrderType()==OP_BUY) {
            if ((OrderOpenPrice() + stopAufEinstandBei) <= Bid && (OrderStopLoss() <(OrderOpenPrice() + spread) )) {
               PrintFormat("Stop auf Einstand: OrderOpenPrice=%.2f, spread = %.2f, stop=%.2f, Bid=%.2f",OrderOpenPrice(),spread, (OrderOpenPrice()+spread),Bid);
               if (!OrderModify(OrderTicket(),0,(OrderOpenPrice() + spread),OrderTakeProfit(),0,clrGreen)){
                       PrintFormat("last error:%i ",GetLastError());                     
               }
            }
         } else if (( OrderOpenPrice() - stopAufEinstandBei) >= Ask && (OrderStopLoss() >(OrderOpenPrice() - spread) )) {
               PrintFormat("Stop auf Einstand: OrderOpenPrice=%.2f, spread = %.2f, stop=%.2f, Ask=%.2f",OrderOpenPrice(),spread, (OrderOpenPrice()-spread),Ask);
               if (!OrderModify(OrderTicket(),0,(OrderOpenPrice() - spread),OrderTakeProfit(),0,clrGreen)){
                       PrintFormat("last error:%i ",GetLastError());                     
               }
         }
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