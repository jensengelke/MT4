//+------------------------------------------------------------------+
//|                                                jensUtilities.mqh |
//|                                                             Jens |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "Jens"
#property link      ""
#property strict


//+------------------------------------------------------------------+
//| defines                                                          |
//+------------------------------------------------------------------+
// #define MacrosHello   "Hello, world!"
// #define MacrosYear    2010
//+------------------------------------------------------------------+
//| DLL imports                                                      |
//+------------------------------------------------------------------+
// #import "user32.dll"
//   int      SendMessageA(int hWnd,int Msg,int wParam,int lParam);
// #import "my_expert.dll"
//   int      ExpertRecalculate(int wParam,int lParam);
// #import
//+------------------------------------------------------------------+
//| EX5 imports                                                      |
//+------------------------------------------------------------------+
// #import "stdlib.ex5"
//   string ErrorDescription(int error_code);
// #import
//+------------------------------------------------------------------+


void ClosePrevious(int Magic, int Slippage)
{
   int total = OrdersTotal();
   for (int i = 0; i < total; i++)
   {
      if (OrderSelect(i, SELECT_BY_POS) == false) continue;
      if ((OrderSymbol() == Symbol()) && (OrderMagicNumber() == Magic))
      {
         int result = 0;
         if (OrderType() == OP_BUY)
         {
            RefreshRates();
            result = OrderClose(OrderTicket(), OrderLots(), Bid, Slippage);
         }
         else if (OrderType() == OP_SELL)
         {
            RefreshRates();
            result = OrderClose(OrderTicket(), OrderLots(), Ask, Slippage);
         }
         
         if (result == -1)
      	{
      		int e = GetLastError();
      		Print("OrderSend Error: ", e);
      	}
      }
   }
}

//+------------------------------------------------------------------+
//| Buy                                                              |
//+------------------------------------------------------------------+
int fBuyNow(double Lots, int Slippage, int Magic, string OrderCommentary, double stopDistance, double takeProfitDistance)
{
	if (!enoughMoneyLeft(1.5)) return -1;
	RefreshRates();
	
	double stopp;
	double tp;
	
	if (NULL == stopDistance) { 
	   stopp = NULL; 
	} else {
	   stopp = (Ask - stopDistance);
   }
   
   if (NULL == takeProfitDistance) {
      tp = NULL;
   } else {
      tp = Ask + takeProfitDistance;
   }
	
	int result = OrderSend(Symbol(), OP_BUY, Lots, Ask, Slippage, stopp, tp, OrderCommentary, Magic,0,clrGreen);
	if (result == -1)
	{
		int e = GetLastError();
		Print("OrderSend Error: ", e);
	}
	return result;
}

//+------------------------------------------------------------------+
//| Sell                                                             |
//+------------------------------------------------------------------+
int fSellNow(double Lots, int Slippage, int Magic, string OrderCommentary, double stopDistance, double takeProfitDistance)
{
   if (!enoughMoneyLeft(1.5)) return -1;
	RefreshRates();
	
	double stopp;
	double tp;
	
	if (NULL == stopDistance) { 
	   stopp = NULL; 
	} else {
	   stopp = (Bid + stopDistance);
   }
   
   if (NULL == takeProfitDistance) {
      tp = NULL;
   } else {
      tp = Bid - takeProfitDistance;
   }
   
	int result = OrderSend(Symbol(), OP_SELL, Lots, Bid, Slippage, stopp, tp, OrderCommentary, Magic,0,clrRed);
	if (result == -1)
	{
		int e = GetLastError();
		Print("OrderSend Error: ", e);
	}
	return result;
}

//+------------------------------------------------------------------+
//| Check what position is currently open										|
//+------------------------------------------------------------------+
int GetCurrentDirection(int Magic)
{
   int total = OrdersTotal();
   for (int cnt = 0; cnt < total; cnt++)
   {
      if (OrderSelect(cnt, SELECT_BY_POS, MODE_TRADES) == false) continue;
      if (OrderMagicNumber() != Magic) continue;
      if (OrderSymbol() != Symbol()) continue;

      if (OrderType() == OP_BUY)
      {
			return 1;
		}
      else if (OrderType() == OP_SELL)
      {
			return -1;
		}
	}
	return 0;
}

bool isNewBar() {
   if (Volume[0] > 1) 
   {
      return false;
   } else {
      return true;
   }
}
  
void closeAllLongPositions(int Magic) {
   for (int i = OrdersTotal()-1; i>=0; i--) {
      if (OrderSelect(i, SELECT_BY_POS, MODE_TRADES) == false) continue;
      if (OrderMagicNumber() != Magic) continue;
      if (OrderSymbol() != Symbol()) continue;

      if (OrderType() == OP_BUY)
      {
			OrderClose(OrderTicket(),OrderLots(),Bid, 3.0,clrGreen);
		}
   }
}

void closeAllShortPositions(int Magic) {
   for (int i = OrdersTotal()-1; i>=0; i--) {
      if (OrderSelect(i, SELECT_BY_POS, MODE_TRADES) == false) continue;
      if (OrderMagicNumber() != Magic) continue;
      if (OrderSymbol() != Symbol()) continue;

      if (OrderType() == OP_SELL)
      {
			OrderClose(OrderTicket(),OrderLots(),Ask, 3.0,clrGreen);
		}
   }
}

double currentRisk(int Magic) {
   double currentRisk = 0.0;
   for (int i = OrdersTotal()-1; i>=0; i--) {
      if (OrderSelect(i, SELECT_BY_POS, MODE_TRADES) == false) continue;
      if (OrderMagicNumber() != Magic) continue;
      if (OrderSymbol() != Symbol()) continue;

      if (OrderType() == OP_SELL)
      {
			currentRisk = currentRisk + (OrderStopLoss() - OrderOpenPrice());
		} else if (OrderType() == OP_BUY) {
		   currentRisk = currentRisk + (OrderOpenPrice() - OrderStopLoss());
		}
   }
  return currentRisk;
}

int currentNumberOfShortPositions(int Magic) {
   int number = 0;
   for (int i = OrdersTotal()-1; i>=0; i--) {
      if (OrderSelect(i, SELECT_BY_POS, MODE_TRADES) == false) continue;
      if (OrderMagicNumber() != Magic) continue;
      if (OrderSymbol() != Symbol()) continue;

      if (OrderType() == OP_SELL)
      {
			number = number + 1;
		}
   }
  return number;
}

int currentNumberOfLongPositions(int Magic) {
   int number = 0;
   for (int i = OrdersTotal()-1; i>=0; i--) {
      if (OrderSelect(i, SELECT_BY_POS, MODE_TRADES) == false) continue;
      if (OrderMagicNumber() != Magic) continue;
      if (OrderSymbol() != Symbol()) continue;

      if (OrderType() == OP_BUY)
      {
			number = number + 1;
		}
   }
  return number;
}

bool handelszeit(string starttime, string stoptime) {
   datetime starttime_dt = StrToTime(starttime);
   datetime stoptime_dt = StrToTime(stoptime);
      
   int startHour = TimeHour(starttime_dt);
   int startMin = TimeMinute(starttime_dt);
   int stopHour = TimeHour(stoptime_dt);
   int stopMin = TimeMinute(stoptime_dt);
   int currHour = TimeHour(TimeCurrent());
   int currMin = TimeMinute(TimeCurrent());
   
   if (currHour < startHour) return false;
   if (currHour > stopHour) return false;
   if (currHour == startHour && currMin < startMin) return false;
   if (currHour == stopHour && currMin > stopMin) return false;
   
   return true;
}

bool danach(string time) {
   
   datetime stoptime_dt = StrToTime(time);
   
   int stopHour = TimeHour(stoptime_dt);
   int stopMin = TimeMinute(stoptime_dt);
   int currHour = TimeHour(TimeCurrent());
   int currMin = TimeMinute(TimeCurrent());
   
   if (currHour < stopHour) return false;
   if (currHour == stopHour && currMin < stopMin) return false;
   
   return true;
}

void closeAllPendingOrders(int Magic) {
   for (int i = OrdersTotal()-1; i>=0; i--) {
      if (OrderSelect(i, SELECT_BY_POS, MODE_TRADES) == false) continue;
      if (OrderMagicNumber() != Magic) continue;
      if (OrderSymbol() != Symbol()) continue;
      int t = OrderType();
      if (t == OP_BUYLIMIT || t == OP_BUYSTOP || t == OP_SELLLIMIT || t == OP_SELLSTOP)
      {
			OrderClose(OrderTicket(),OrderLots(),Bid, 3.0,clrGreen);
		}
   }
}


bool HLineCreate(const long            chart_ID=0,        // chart's ID 
                 const string          name="HLine",      // line name 
                 const int             sub_window=0,      // subwindow index 
                 double                price=0,           // line price 
                 const color           clr=clrRed,        // line color 
                 const ENUM_LINE_STYLE style=STYLE_SOLID, // line style 
                 const int             width=1,           // line width 
                 const bool            back=false,        // in the background 
                 const bool            selection=true,    // highlight to move 
                 const bool            hidden=true,       // hidden in the object list 
                 const long            z_order=0)         // priority for mouse click 
  { 
//--- if the price is not set, set it at the current Bid price level 
   if(!price) 
      price=SymbolInfoDouble(Symbol(),SYMBOL_BID); 
//--- reset the error value 
   ResetLastError(); 
//--- create a horizontal line 
   if(!ObjectCreate(chart_ID,name,OBJ_HLINE,sub_window,0,price)) 
     { 
      Print(__FUNCTION__, 
            ": failed to create a horizontal line! Error code = ",GetLastError()); 
      return(false); 
     } 
//--- set line color 
   ObjectSetInteger(chart_ID,name,OBJPROP_COLOR,clr); 
//--- set line display style 
   ObjectSetInteger(chart_ID,name,OBJPROP_STYLE,style); 
//--- set line width 
   ObjectSetInteger(chart_ID,name,OBJPROP_WIDTH,width); 
//--- display in the foreground (false) or background (true) 
   ObjectSetInteger(chart_ID,name,OBJPROP_BACK,back); 
//--- enable (true) or disable (false) the mode of moving the line by mouse 
//--- when creating a graphical object using ObjectCreate function, the object cannot be 
//--- highlighted and moved by default. Inside this method, selection parameter 
//--- is true by default making it possible to highlight and move the object 
   ObjectSetInteger(chart_ID,name,OBJPROP_SELECTABLE,selection); 
   ObjectSetInteger(chart_ID,name,OBJPROP_SELECTED,selection); 
//--- hide (true) or display (false) graphical object name in the object list 
   ObjectSetInteger(chart_ID,name,OBJPROP_HIDDEN,hidden); 
//--- set the priority for receiving the event of a mouse click in the chart 
   ObjectSetInteger(chart_ID,name,OBJPROP_ZORDER,z_order); 
//--- successful execution 
   return(true); 
  } 


void manageStops(int myMagic, double stopForLong, double stopForShort) {

   for (int i = OrdersTotal()-1; i>=0; i--) {
      if (OrderSelect(i, SELECT_BY_POS, MODE_TRADES) == false) continue;
      if (OrderMagicNumber() != myMagic) continue;
      if (OrderSymbol() != Symbol()) continue;

      if (OrderType() == OP_SELL) {
			if (OrderStopLoss() > stopForShort) {
			   OrderModify(OrderTicket(),0,stopForShort,0,0,clrRed);
			}
		}
		
		if (OrderType() == OP_BUY) {
			if (OrderStopLoss() < stopForLong) {
			   OrderModify(OrderTicket(),0,stopForLong,0,0,clrRed);
			}
		}
   }  
}

bool enoughMoneyLeft(double threshold) {
      double equity = AccountEquity();
      double margin = AccountMargin();
      
      if ((margin/equity) < threshold) return true;
      Print("out of Margin!");     
      return false;
}