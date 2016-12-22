//+------------------------------------------------------------------+
//|                                                  JensUtils.h.mqh |
//|                                                       mehr davon |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "mehr davon"
#property link      "https://www.mql5.com"
#property strict

double currentRisk(int myMagic) {
   double currentRisk = 0.0;
   for (int i=OrdersTotal();i>=0;i--) {
      OrderSelect(i,SELECT_BY_POS,MODE_TRADES);
      if (OrderMagicNumber() != myMagic) continue;
      if (OrderSymbol() != Symbol()) continue;
      if (OrderCloseTime()>0) continue;
     
      if (OrderType() == OP_BUY){
         currentRisk+=OrderLots() * (OrderOpenPrice() - OrderStopLoss());
      }
      if (OrderType() == OP_SELL) {
        currentRisk+=OrderLots() * (OrderStopLoss()- OrderOpenPrice());
      }
   }
   return currentRisk;
}


double lots(double baseLots, double accountSize) {
   double lots = baseLots;
   double equityPercentage = AccountEquity()/AccountBalance();
   int equityTimes = MathFloor( (AccountEquity()/accountSize) * equityPercentage );  // how many time is present equity times BaseEquity
   if(equityTimes >= 1) {
         lots = baseLots*equityTimes;                 // total new open Lots
   }         
   if (lots > MarketInfo(Symbol(), MODE_MAXLOT)) {
      lots = MarketInfo(Symbol(), MODE_MAXLOT);
   }
   return lots;
}

double lotsByRisk(double points, double riskSize, int lotDigits) {
   double risk = riskSize * AccountEquity();
   double tickValue = MarketInfo(Symbol(),MODE_TICKVALUE);
   double tickSize =  MarketInfo(Symbol(),MODE_TICKSIZE);
   double lots = (risk * tickValue) / (points*tickSize);
   lots = NormalizeDouble(lots,lotDigits);
   return lots;   
}

void closeAllPendingOrders(int myMagic) {
 for (int i=OrdersTotal();i>=0;i--) {
      OrderSelect(i,SELECT_BY_POS,MODE_TRADES);
      if (OrderMagicNumber() != myMagic) continue;
      if (OrderSymbol() != Symbol()) continue;
      if (OrderType() == OP_BUYSTOP ||
         OrderType() == OP_SELLSTOP ||
         OrderType() == OP_SELLLIMIT ||
         OrderType() == OP_BUYLIMIT) {
         OrderDelete(OrderTicket(),clrWhite);
      }
   }
}

int countOpenPendingOrders(int myMagic) {
   int openPendingOrders = 0;
   for (int i=OrdersTotal();i>=0;i--) {
      OrderSelect(i,SELECT_BY_POS,MODE_TRADES);
      if (OrderMagicNumber() != myMagic) continue;
      if (OrderSymbol() != Symbol()) continue;
      if (OrderType() == OP_BUYSTOP ||
         OrderType() == OP_SELLSTOP ||
         OrderType() == OP_SELLLIMIT ||
         OrderType() == OP_BUYLIMIT) {
         openPendingOrders++;
      }
   }
   return openPendingOrders;
}

int countOpenPositions(int myMagic) {
   int openPositons = 0;
   for (int i=OrdersTotal();i>=0;i--) {
      OrderSelect(i,SELECT_BY_POS,MODE_TRADES);
      if (OrderMagicNumber() != myMagic) continue;
      if (OrderSymbol() != Symbol()) continue;
      if (OrderType() == OP_BUY ||
         OrderType() == OP_SELL) {
         openPositons++;
      }
   }
   return openPositons;
}

int countOpenPositions(int myMagic, int mode) {
   int openPositons = 0;
   for (int i=OrdersTotal();i>=0;i--) {
      OrderSelect(i,SELECT_BY_POS,MODE_TRADES);
      if (OrderMagicNumber() != myMagic) continue;
      if (OrderSymbol() != Symbol()) continue;
      if (OrderType() == mode) {
         openPositons++;
      }
   }
   return openPositons;
}


void closeAllOpenOrders(int myMagic) {
 RefreshRates();
 for (int i=OrdersTotal();i>=0;i--) {
      OrderSelect(i,SELECT_BY_POS,MODE_TRADES);
      if (OrderMagicNumber() != myMagic) continue;
      if (OrderSymbol() != Symbol()) continue;
      if (OrderType() == OP_BUY) {
         OrderClose(OrderTicket(),OrderLots(),Bid,2,clrWhite);
      }
      
      if (OrderType() == OP_SELL) {
         OrderClose(OrderTicket(),OrderLots(),Ask,2,clrWhite);
      }
   }
}

void closeLongPositions(int myMagic) {
 RefreshRates();
 for (int i=OrdersTotal();i>=0;i--) {
      OrderSelect(i,SELECT_BY_POS,MODE_TRADES);
      if (OrderMagicNumber() != myMagic) continue;
      if (OrderSymbol() != Symbol()) continue;
      if (OrderType() == OP_BUY) {
         OrderClose(OrderTicket(),OrderLots(),Bid,2,clrWhite);
      }
   }
}

void closeShortPositions(int myMagic) {
 RefreshRates();
 for (int i=OrdersTotal();i>=0;i--) {
      OrderSelect(i,SELECT_BY_POS,MODE_TRADES);
      if (OrderMagicNumber() != myMagic) continue;
      if (OrderSymbol() != Symbol()) continue;
      if (OrderType() == OP_SELL) {
         OrderClose(OrderTicket(),OrderLots(),Ask,2,clrWhite);
      }
   }
}

int currentDirectionOfOpenPositions(int myMagic) {
   int direction = 0;
   for (int i=OrdersTotal();i>=0;i--) {
      OrderSelect(i,SELECT_BY_POS,MODE_TRADES);
      if (OrderMagicNumber() != myMagic) continue;
      if (OrderSymbol() != Symbol()) continue;
      if (OrderType() == OP_BUY) {
         direction = direction + 1;
      }
      
      if (OrderType() == OP_SELL) {
         direction = direction - 1;
      }
   }
   return direction;
}

bool isHandelszeit(string startTime, string endTime) {

   if (DayOfWeek()<1 || DayOfWeek()>5) {
      return false;
   }
   
   string startTimeString = StringFormat("%4i.%02i.%02i %s",TimeYear(TimeLocal()),TimeMonth(TimeLocal()), TimeDay(TimeLocal()), startTime);
   string endTimeString = StringFormat("%4i.%02i.%02i %s",TimeYear(TimeLocal()),TimeMonth(TimeLocal()), TimeDay(TimeLocal()), endTime);
         
   datetime startDt = StrToTime(startTimeString);
   datetime endDt = StrToTime(endTimeString);
   
   if (TimeLocal() >= startDt && TimeLocal()<=endDt) {
      return true;
   }
   return false;
}

bool isHandelszeit(int startHour, int startMinute, int endHour, int endMinute) {

   string startTimeString = StringFormat("%2i:%2i", startHour,startMinute);
   string endTimeString = StringFormat("%2i:%2i", endHour, endMinute);
         
   return isHandelszeit(startTimeString, endTimeString);
}

void trailInProfit(int myMagic, double distance) {
      if (0 == distance) return;
      RefreshRates();
      double stopForLong = Bid - distance;
      double stopForShort = Ask + distance;
     
      trail(myMagic,stopForShort,stopForLong,true);
}

void stopAufEinstand(int myMagic, double distance) {
   if (0==distance) return;
    double spread = NormalizeDouble(Ask - Bid, Digits);
    
    
      
      for (int i=OrdersTotal();i>=0;i--) {
         OrderSelect(i,SELECT_BY_POS,MODE_TRADES);         
         if (OrderMagicNumber() != myMagic) {continue;}
         if (OrderSymbol() != Symbol()) {continue;}
         if (OrderType()==OP_BUY) {
            if ((OrderOpenPrice() + distance) <= Bid) {
               double targetStop = NormalizeDouble(OrderOpenPrice() + spread,Digits );
               if (OrderStopLoss() < targetStop)  {
                  PrintFormat("Stop auf Einstand long: OrderOpenPrice=%.2f, spread = %.2f, Bid=%.2f, oldstop=%.2f, targetStop=%.2f",OrderOpenPrice(),spread, Bid, OrderStopLoss(),targetStop);
                  if (!OrderModify(OrderTicket(),0,targetStop,0,0,clrGreen)) {
                          PrintFormat("last error stop auf einstand:%i; bid=%.5f, ask=%.5f, orderOpenPrice=%.5f, newStop=%.5f, oldStop=%.5f ",
                           GetLastError(), Bid, Ask, OrderOpenPrice(), (OrderOpenPrice() + spread),OrderStopLoss());
                  }
               }
            }
         }
         if (OrderType()==OP_SELL) {
            double targetStop = NormalizeDouble(OrderOpenPrice() - spread,Digits );
            if ((OrderOpenPrice() - distance) >= Ask && OrderStopLoss() > targetStop) {
               
               PrintFormat("Stop auf Einstand short: OrderOpenPrice=%.2f, spread = %.2f, oldstop=%.2f, Ask=%.2f, targetstop=%.2f",OrderOpenPrice(),spread, OrderStopLoss(),Ask, targetStop);
               if (!OrderModify(OrderTicket(),0,targetStop,0,0,clrGreen)) {
                     PrintFormat("last error stop auf einstand short:%i; bid=%.5f, ask=%.5f, orderOpenPrice=%.5f, newStop=%.5f, oldStop=%.5f  ",
                        GetLastError(), Bid, Ask, OrderOpenPrice(), (OrderOpenPrice() - spread),OrderStopLoss());                
               }
            }
         }
      }
}

void trailWithLastXCandle(int myMagic, int x) {

      if (0 == x) return;
      RefreshRates();
      double stopForLong = Low[iLowest(NULL,PERIOD_CURRENT,MODE_LOW,x,0)];
      double stopForShort = High[iHighest(NULL,PERIOD_CURRENT,MODE_HIGH,x,0)];
      trail(myMagic,stopForShort,stopForLong, false);
 
}

void trail(int myMagic, double stopForShort, double stopForLong, bool inProfit) {
     for (int i=OrdersTotal();i>=0;i--) {
         OrderSelect(i,SELECT_BY_POS,MODE_TRADES);
         if (OrderMagicNumber() != myMagic) {continue;}
         if (OrderSymbol() != Symbol()) {continue;}
         if (OrderProfit() > 0) {
            if (OrderType() == OP_BUY && stopForLong > 0) {
               if (OrderStopLoss() < stopForLong) {
                 if (stopForLong > (OrderOpenPrice() + (Ask-Bid)) || !inProfit) {
                    if (!OrderModify(OrderTicket(),0,stopForLong,OrderTakeProfit(),0,clrGreen)) {
                     PrintFormat("last error trail long:%i ",GetLastError());                     
                    }
                 }
               }
               continue;
            } 
            if (OrderType() == OP_SELL && stopForShort > 0) {
               if (OrderStopLoss() > stopForShort) {
                  if (stopForShort < (OrderOpenPrice() - (Ask-Bid)) || !inProfit) {
                     if (!OrderModify(OrderTicket(),0,stopForShort,OrderTakeProfit(),0,clrRed)) {
                       PrintFormat("last error trail short:%i ",GetLastError());                      
                     }
                  }
               }
            }
         }
     }
}

void trailWithMA(int myMagic, double maValue) {

      if (0 == maValue) return;
      RefreshRates();
      trail(myMagic,maValue,maValue,false);
}


int openLongPosition(int myMagic, double lots, double price, double stopLoss, double takeProfit) {
   RefreshRates();
   
   double orderLots = NormalizeDouble(lots,1);
   double orderPrice = NormalizeDouble(price,Digits);
   double orderStop = NormalizeDouble(stopLoss,Digits);
   double orderProfit = NormalizeDouble(takeProfit,Digits);
   
   int ticket = OrderSend(NULL,OP_BUY,orderLots,orderPrice,3, orderStop,orderProfit,NULL,myMagic,0,clrGreen);     
   if (-1 == ticket) {
      Print("buy last error: " + GetLastError());   
   } else {
     // Print("ticket:" + ticket);
   }
   
   return ticket;
}

int openShortPosition(int myMagic, double lots, double price, double stopLoss, double takeProfit) {
   RefreshRates();
   
   double orderLots = NormalizeDouble(lots,1);
   double orderPrice = NormalizeDouble(price,Digits);
   double orderStop = NormalizeDouble(stopLoss,Digits);
   double orderProfit = NormalizeDouble(takeProfit,Digits);
   
   int ticket = OrderSend(NULL,OP_SELL,orderLots,orderPrice, 3,orderStop,orderProfit,NULL,myMagic,0,clrRed);
   if (-1 == ticket) {
      Print("sell last error: " + GetLastError());   
   } else {
      //Print("ticket:" + ticket);
   }
   
   return ticket;
}

void timeout(int myMagic, datetime closeIfOpenedBefore) {
   for (int i=OrdersTotal();i>=0;i--) {
         OrderSelect(i,SELECT_BY_POS,MODE_TRADES);
         if (OrderMagicNumber() != myMagic) {continue;}
         if (OrderSymbol() != Symbol()) {continue;}
         if (OrderOpenTime()< closeIfOpenedBefore) {
         
            if (OrderType() == OP_BUY) {
               OrderClose(OrderTicket(),OrderLots(),Bid,3,clrGreen);
               continue;
            } 
            if (OrderType() == OP_SELL) {
               OrderClose(OrderTicket(),OrderLots(),Ask,3,clrGreen);
               continue;
            }
         }
         
     }
}