//findet eine langweilige range und platziert stop buy/sell knapp hinter den 
//range grenzen

#property copyright "Ausbruch"
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

#include "../Include/JensUtils.mqh";

extern int startHour = 8;
extern int startMinute = 0;
extern int endHour = 21;
extern int endMinute = 58;

extern bool overNight = true;
extern int myMagic = 20161020;
extern double baseLots = 0.2;
extern double accountSize = 1000.0;
extern double fixedTakeProfit = 0.0;
extern double initialStop = 0.0;
extern double trailInProfit = 10.0;
extern int boringCandles = 60;
extern double boringRange = 20.0;
extern double buffer = 5.0;
extern int orderExpiryInMin = 3600;
static datetime lastTradeTime = NULL;
extern int maxOpenPositions = 5;

string screenString = "StatusWindow";
string screenHighLine = "highLine";
string screenLowLine = "lowLine";
string screenRect = "Range";

double highestHighExecution = 0.0;
double lowestLowExecution = 0.0;
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
   if (trailInProfit==0 && fixedTakeProfit==0) {
      return(INIT_FAILED);
   }
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
   
     if (
      DayOfWeek()<1 || 
      DayOfWeek()>5 ||
      TimeHour(TimeLocal())<startHour || 
      TimeHour(TimeLocal())> endHour ||
      ( TimeHour(TimeLocal())== endHour &&  TimeMinute(TimeLocal())>=endMinute)) {
         closeAllPendingOrders(myMagic);
         closeAllOpenOrders(myMagic);
      return;
   }
      
   if(lastTradeTime == Time[0]) {
      return;
   } else {
      lastTradeTime = Time[0];
   }
   
   double lowestLow = Low[iLowest(NULL,PERIOD_CURRENT,MODE_LOW,boringCandles,0)];
   double highestHigh = High[iHighest(NULL,PERIOD_CURRENT,MODE_HIGH,boringCandles,0)];
   int openPendingPos = countOpenPendingOrders(myMagic);
   int openPos = countOpenPositions(myMagic);
   
   string status = StringFormat("currentRisk=%.2f, boringRange=%.2f",currentRisk(myMagic), (highestHigh-lowestLow) );     
   
   ObjectDelete(screenString);
   ObjectCreate(screenString, OBJ_LABEL, 0, 0, 0);
   ObjectSetText(screenString,status, 12, "Arial Bold", Lime);
   ObjectSet(screenString, OBJPROP_CORNER, 3);
   ObjectSet(screenString, OBJPROP_XDISTANCE, 5);
   ObjectSet(screenString, OBJPROP_YDISTANCE, 5); 
   
   ObjectDelete(screenHighLine);
   ObjectCreate(0,screenHighLine,OBJ_HLINE,0,0,highestHigh);
   ObjectSetInteger(0,screenHighLine,OBJPROP_COLOR,clrBlue); 
   ObjectSetInteger(0,screenHighLine,OBJPROP_STYLE,STYLE_SOLID);
   ObjectSetInteger(0,screenHighLine,OBJPROP_WIDTH,3); 
   
   ObjectDelete(screenLowLine);
   ObjectCreate(0,screenLowLine,OBJ_HLINE,0,0,lowestLow);
   ObjectSetInteger(0,screenLowLine,OBJPROP_COLOR,clrBlue); 
   ObjectSetInteger(0,screenLowLine,OBJPROP_STYLE,STYLE_SOLID);
   ObjectSetInteger(0,screenLowLine,OBJPROP_WIDTH,3); 
   
   ObjectDelete(screenRect);
   
   ObjectCreate(screenRect, OBJ_RECTANGLE, 0,TimeCurrent()-60*boringCandles*Period(),highestHigh,TimeCurrent(),lowestLow);
   ObjectSet(screenRect, OBJPROP_BACK, true);
   ObjectSet(screenRect, OBJPROP_COLOR, clrBlue);
   ObjectSet(screenRect, OBJPROP_STYLE, STYLE_SOLID);

    
   if (
      DayOfWeek()<1 || 
      DayOfWeek()>5 ||
      TimeHour(TimeLocal())<8 || 
      TimeHour(TimeLocal())>22 ||
      ( TimeHour(TimeLocal())>21 &&  TimeMinute(TimeLocal())>58)) {
         closeAllPendingOrders(myMagic);
      return;
   }
   
   
  
   
      
   if (
      (boringRange > (highestHigh - lowestLow)  && (0==openPendingPos)) ||
      //if there is just one open pending order, we can create another one (likely in the other direction)
      (openPos > 0 && 0 <=currentRisk(myMagic) && (openPendingPos + openPos)<maxOpenPositions) 
   ) {
      openLongPosition(lots(baseLots,accountSize),highestHigh + buffer, initialStop ,fixedTakeProfit);
      openShortPosition(lots(baseLots,accountSize),lowestLow - buffer, initialStop, fixedTakeProfit);
   }

   
   if (trailInProfit > 0) {
      RefreshRates();
      double stopForLong = Bid - trailInProfit;
      double stopForShort = Ask + trailInProfit;
     
      for (int i=OrdersTotal();i>=0;i--) {
         OrderSelect(i,SELECT_BY_POS,MODE_TRADES);
         if (OrderMagicNumber() != myMagic) {continue;}
         if (OrderSymbol() != Symbol()) {continue;}
         if (OrderProfit() > 0) {
            if (OrderType() == OP_BUY && stopForLong > 0) {
               if (OrderStopLoss() < stopForLong) {
                 OrderModify(OrderTicket(),0,stopForLong,OrderTakeProfit(),0,clrGreen);
               }
               continue;
            } 
            if (OrderType() == OP_SELL && stopForShort > 0) {
               if (OrderStopLoss() > stopForShort) {
                  OrderModify(OrderTicket(),0,stopForShort,OrderTakeProfit(),0,clrRed);
               }
            }
         }
     }
   }
   
  }
//+------------------------------------------------------------------+

void openLongPosition(double lots, double price, double stopLoss, double takeProfit) {

   double stop = 0;
   double tp = 0;
   
   if (stopLoss != 0) {
      stop = price - stopLoss;
   }
   if (takeProfit != 0) {
      tp = price +  takeProfit;
   }
   highestHighExecution = price;
   OrderSend(NULL,OP_BUYSTOP,lots,price,5.0,stop,tp,NULL,myMagic,TimeLocal()+(orderExpiryInMin),clrGreen);        
}

void openShortPosition(double lots, double price, double stopLoss, double takeProfit) {
   double stop = 0;
   double tp = 0;
   if (stopLoss != 0) {
      stop = price + stopLoss;
   }
   if (takeProfit != 0) {
      tp = price - takeProfit;
   }
   lowestLowExecution = price;
   OrderSend(NULL,OP_SELLSTOP,lots,price,5.0,stop,tp,NULL,myMagic,TimeCurrent()+(orderExpiryInMin),clrRed);
}


bool pendingOrderAt(int orderType, double price) {
   bool exists = false;
   for (int i=OrdersTotal();i>=0;i--) {
         OrderSelect(i,SELECT_BY_POS,MODE_TRADES);
         if (OrderMagicNumber() != myMagic) {continue;}
         if (OrderSymbol() != Symbol()) {continue;}
         if (!OrderType()==orderType) {continue;}
         PrintFormat("looking for order at %.2f, found %.2f", price, OrderOpenPrice());
         if (!OrderOpenPrice()==price) {continue;}
         exists = true;
         break;
     }
   return exists;
}