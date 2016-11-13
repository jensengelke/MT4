//+------------------------------------------------------------------+
//|                                                      system5.mq4 |
//|                                                       mehr davon |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "mehr davon"
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

#include "../Include/JensUtils.mqh";

extern bool overNight = true;
extern int myMagic = 20161028;
extern double baseLots = 0.2;
extern double accountSize = 1000.0;
extern double fixedTakeProfit = 0.0;
extern double initialStop = 0.0;
extern double trailInProfit = 10.0;
extern int extremeCandles = 60;
extern double buffer = 5.0;
extern int orderExpiryInMin = 3600;
static datetime lastTradeTime = NULL;
extern int maxPositions = 5;
extern int initialStopAtXCandleExtreme = 5;
extern int trailWithXCandleExtreme = 5;

string screenString = "StatusWindow";
string screenHighLine = "highLine";
string screenLowLine = "lowLine";

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
   if ( (fixedTakeProfit==0.0 && trailInProfit==0.0 && trailWithXCandleExtreme==0) ||
      (trailInProfit!=0 && trailWithXCandleExtreme !=0) ||
      (initialStop!=0 && initialStopAtXCandleExtreme!=0) ||
      (initialStop==0 && initialStopAtXCandleExtreme==0) ||
      (orderExpiryInMin < 900) ) {
      return (INIT_FAILED);
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
  if(lastTradeTime == Time[0]) {
      //return;
   } else {
      lastTradeTime = Time[0];
   }
  
   double lowestLow = Low[iLowest(NULL,PERIOD_CURRENT,MODE_LOW,extremeCandles,0)];
   double highestHigh = High[iHighest(NULL,PERIOD_CURRENT,MODE_HIGH,extremeCandles,0)];
   int openPos = countOpenPositions(myMagic);
   int openPendingPos = countOpenPendingOrders(myMagic);
   double risk = currentRisk(myMagic);
   string status = StringFormat("spread=%.5f, currentRisk=%.2f, highest high=%.2f, lowest low=%.2f",(Bid-Ask),risk,highestHigh,lowestLow);   
      
   ObjectDelete(screenString);
   ObjectCreate(screenString, OBJ_LABEL, 0, 0, 0);
   if (risk <=0) {
      ObjectSetText(screenString,status, 8, "Arial Bold", clrGreen);
   } else {
     ObjectSetText(screenString,status, 8, "Arial Bold", clrRed);
   }
   ObjectSet(screenString, OBJPROP_CORNER, 3);
   ObjectSet(screenString, OBJPROP_XDISTANCE, 10);
   ObjectSet(screenString, OBJPROP_YDISTANCE, 10); 
 
    if (
      DayOfWeek()<1 || 
      DayOfWeek()>5 ||
      TimeHour(TimeLocal())<8 || 
      TimeHour(TimeLocal())>22 ||
      ( TimeHour(TimeLocal())>21 &&  TimeMinute(TimeLocal())>58)) {
         closeAllPendingOrders(myMagic);
         closeAllOpenOrders(myMagic);
      return;
   }
   
   
   if (TimeHour(TimeLocal())>8 &&
         ( 
          (0==openPendingPos && 0==openPos) ||
          ((openPos>0) && ((openPos+openPendingPos)<maxPositions) && (currentRisk(myMagic)<=0)) // open positions, but no risk
         )) {
      //open new positions?
      if ((High[1] == highestHigh) || (High[0] == highestHigh)) {
          double stop = 0;
          if (initialStop > 0) {
            stop = initialStop;
          } else if (initialStopAtXCandleExtreme>0) {
            stop = highestHigh + buffer - Low[iLowest(NULL,PERIOD_CURRENT,MODE_LOW,initialStopAtXCandleExtreme,0)];
          }
         openLongPosition(lots(baseLots, accountSize),highestHigh + buffer, stop , fixedTakeProfit);
      }   
      if (Low[1] <= lowestLow || Low[0] <= lowestLow) {
         double stop = initialStop;
         if (initialStop > 0) {
            stop = initialStop;
          } else if (initialStopAtXCandleExtreme>0) {
            stop = (High[iHighest(NULL,PERIOD_CURRENT,MODE_HIGH,initialStopAtXCandleExtreme,0)] - lowestLow - buffer);
          }
          openShortPosition(lots(baseLots, accountSize),lowestLow - buffer, stop, fixedTakeProfit);
      }
   }
   
   double spread=Bid-Ask;
   if (trailInProfit > 0 || trailWithXCandleExtreme>0) {
      RefreshRates();
      double stopForLong,stopForShort;
      
      if (trailInProfit > 0) {
         stopForLong = Bid - trailInProfit;
         stopForShort = Ask + trailInProfit;
      } else {
         stopForLong = Low[iLowest(NULL,PERIOD_CURRENT,MODE_LOW,trailWithXCandleExtreme,0)];
         stopForShort = High[iHighest(NULL,PERIOD_CURRENT,MODE_HIGH,initialStopAtXCandleExtreme,0)];
      }
      
      for (int i=OrdersTotal();i>=0;i--) {
         OrderSelect(i,SELECT_BY_POS,MODE_TRADES);
         if (OrderMagicNumber() != myMagic) {continue;}
         if (OrderSymbol() != Symbol()) {continue;}
         if (OrderProfit() > 0) {
            if (OrderType() == OP_BUY && stopForLong > 0) {
               if (OrderStopLoss() < stopForLong && OrderOpenPrice()<stopForLong) {
                 OrderModify(OrderTicket(),0,stopForLong,OrderTakeProfit(),0,clrGreen);
               }
               continue;
            } 
            if (OrderType() == OP_SELL && stopForShort > 0) {
               if (OrderStopLoss() > stopForShort && OrderOpenPrice()>stopForShort) {
                  OrderModify(OrderTicket(),0,stopForShort,OrderTakeProfit(),0,clrRed);
               }
            }
         }
     }
   }


  }
//+------------------------------------------------------------------+


void openLongPosition(double lots, double price, double stopLoss, double takeProfit) {
   RefreshRates();
   double stop = 0;
   double tp = 0;
   
   if (Ask >= price) {
      if (stopLoss != 0) {
         stop = Ask - stopLoss;
      }
      if (takeProfit != 0) {
         tp = Ask +  takeProfit;
      }
      OrderSend(NULL,OP_BUY,lots,Ask,2.0,stop,tp,NULL,myMagic,0,clrGreen);        
   } else {
      if (stopLoss != 0) {
         stop = price - stopLoss;
      }
      if (takeProfit != 0) {
         tp = price +  takeProfit;
      }
      if (!pendingOrderAt(OP_BUYSTOP, price)) {
         int ticket = OrderSend(NULL,OP_BUYSTOP,lots,price,5,stop,tp,NULL,myMagic,TimeCurrent()+(orderExpiryInMin),clrGreen);     
         if (-1 == ticket) {
            Print("last error: " + GetLastError());   
         } else {
            Print("ticket:" + ticket);
         }
      }
   }
}

void openShortPosition(double lots, double price, double stopLoss, double takeProfit) {
   RefreshRates();
   double stop = 0;
   double tp = 0;
   
   if (Bid >= price) {
      if (stopLoss != 0) {
         stop = Bid + stopLoss;
      }
      if (takeProfit != 0) {
         tp = Bid - takeProfit;
      }
      OrderSend(NULL,OP_SELL,lots,Bid,2.0,stop,tp,NULL,myMagic,0,clrGreen);        
   } else {
      if (stopLoss != 0) {
         stop = price + stopLoss;
      }
      if (takeProfit != 0) {
         tp = price - takeProfit;
      }
      if (!pendingOrderAt(OP_SELLSTOP, price)) {
         OrderSend(NULL,OP_SELLSTOP,lots,price,2,stop,tp,NULL,myMagic,TimeCurrent()+(orderExpiryInMin),clrRed);
      }
   }
   
}

bool pendingOrderAt(int orderType, double price) {
   bool exists = false;
   for (int i=OrdersTotal();i>=0;i--) {
         OrderSelect(i,SELECT_BY_POS,MODE_TRADES);
         if (OrderMagicNumber() != myMagic) {continue;}
         if (OrderSymbol() != Symbol()) {continue;}
         if (!OrderType()==orderType) {continue;}
         if (!OrderOpenPrice()==price) {continue;}
         exists = true;
         break;
     }
   return exists;
}
