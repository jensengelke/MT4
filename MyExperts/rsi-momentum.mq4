//+------------------------------------------------------------------+
//|                                                 rsi-momentum.mq4 |
//|                        Copyright 2019, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2019, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

input string label0 = "" ; //+--- admin ---+
input int    myMagic = 20;
input int    tracelevel = 2;
input bool   backtest = true; //display balance and equity in chart
input string chartLabel = "RSI momentum";

input string label1 = "" ; //+--- entry signal ---+
input int    rsiPeriod = 12;
input double rsiDistance = 15.0; //RSI threshold in % from upper and lower end

input string label2 = ""; //+--- money management ---+
input double riskInPercent = 1.0;
input double tpPoints = 50;
input double trailingStopPoints = 30.0;
input double initialStopPoints = 30.0;
input int    initialStopBarsLookback = 6;
input int    entryLookback = 2;

double rsiLowThreshold = rsiDistance;
double rsiHighThreshold = 100 - rsiDistance;
static int pendingLongTicket = -1;
static int pendingShortTicket = -1;
static int longTicket = -1;
static int shortTicket = -1;
static datetime lastTradeTime = NULL;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
int OnInit()
  {
//---
   for (int i=OrdersTotal();i>=0;i--) {
      if (  OrderSelect(i, SELECT_BY_POS) && 
            OrderMagicNumber() == myMagic) {     
         if (OrderType() == OP_BUYSTOP) pendingLongTicket = OrderTicket();
         if (OrderType() == OP_SELLSTOP) pendingShortTicket = OrderTicket();
         if (OrderType() == OP_BUY) longTicket = OrderTicket();
         if (OrderType() == OP_SELL) shortTicket = OrderTicket();
      }      
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
   if (longTicket != -1 && OrderSelect(longTicket,SELECT_BY_TICKET)) {
      if (OrderCloseTime() != 0) {
         longTicket = -1;
      }
   }
   
   if (shortTicket != -1 && OrderSelect(shortTicket,SELECT_BY_TICKET)) {
      if (OrderCloseTime() != 0) {
         shortTicket = -1;
      }
   }  
  
   if (-1 != pendingLongTicket && OrderSelect(pendingLongTicket,SELECT_BY_TICKET)) {
      if (OrderType() == OP_BUY) {
         pendingLongTicket = -1;
         longTicket = OrderTicket();
      }
   }
  
   if (-1 != pendingShortTicket && OrderSelect(pendingShortTicket,SELECT_BY_TICKET)) {
      if (OrderType() == OP_SELL) {
         pendingShortTicket = -1;
         shortTicket = OrderTicket();
      }
   }
   
   trail();
   
   if (Time[0] == lastTradeTime) return;   
   lastTradeTime = Time[0];   
   
   if (backtest) Comment("RSI extreme: RSI=", rsiDistance, ", risk: ", riskInPercent);
   
   double rsi = iRSI(Symbol(),PERIOD_CURRENT,rsiPeriod,PRICE_CLOSE,1);
   
   //if (tracelevel>=2) PrintFormat("I0001 evaluating entry RSI: %.2f ", rsi);
   
   if (pendingLongTicket != -1) { //new pending long
      OrderDelete(pendingLongTicket,clrBlack);   
      pendingLongTicket = -1;
   }
   
   if (pendingShortTicket != -1) { //new pending long
      if (OrderDelete(pendingShortTicket,clrBlack)) {
         pendingShortTicket = -1;
      }
   }
   
   if (rsi < rsiLowThreshold && shortTicket == -1) {
       
      double entry = Low[iLowest(_Symbol,PERIOD_CURRENT,MODE_LOW,entryLookback,0)];
      double stop  = High[iHighest(_Symbol,PERIOD_CURRENT,MODE_HIGH,initialStopBarsLookback,0)];
      if (initialStopPoints > 0.0) stop = entry + (initialStopPoints * _Point);
      PrintFormat("short entry %.5f, stop %.5f", entry, stop);
      double tp    = entry - (tpPoints * _Point);
      double lots  = lotsByRisk(stop - entry);
      if (tracelevel>=2) PrintFormat("entry %.5f, stop %.5f, tp %.5f, lots %.5f", entry,stop, tp, lots);
      pendingShortTicket = OrderSend(_Symbol,OP_SELLSTOP,lots,entry,10,stop,tp,"RSI extreme",myMagic,0,clrGreen);
   }
   
   if (rsi > rsiHighThreshold && longTicket == -1) {
       
      double entry = High[iHighest(_Symbol,PERIOD_CURRENT,MODE_HIGH,entryLookback,0)];
      double stop  = Low[iLowest(_Symbol,PERIOD_CURRENT,MODE_LOW,initialStopBarsLookback,0)];
      if (initialStopPoints > 0.0) stop = entry -  (initialStopPoints * _Point);
      PrintFormat("long entry %.5f, stop %.5f", entry, stop);
      double tp    = entry +(tpPoints * _Point);
      double lots  = lotsByRisk(entry-stop);
      if (tracelevel>=2) PrintFormat("entry %.5f, stop %.5f, tp %.5f lots %.5f", entry,stop, tp,lots);
      pendingLongTicket = OrderSend(_Symbol,OP_BUYSTOP,lots, entry,10,stop,tp,"RSI extreme",myMagic,0,clrRed);
   }
   
   
  }
//+------------------------------------------------------------------+

double lotsByRisk(double stopDistance) {
   if (0==stopDistance) return 0.0;
   //PrintFormat("passed symbol_digits=%i, mode_points says: %i",lotDigits, MarketInfo(Symbol(),MODE_DIGITS));
   double equityAtRisk = (riskInPercent/100) * AccountEquity();
   //PrintFormat("equity to risk: %.2f with stopDistance=%.2f",equityAtRisk,stopDistance);
   double lots = equityAtRisk / (MathAbs(stopDistance) * MarketInfo(Symbol(),MODE_LOTSIZE));
   lots = NormalizeDouble(lots,2); //TODO
   
   if (lots > MarketInfo(Symbol(),MODE_MAXLOT)) {
      lots = MarketInfo(Symbol(),MODE_MAXLOT);
   }
   if (lots < MarketInfo(Symbol(),MODE_MINLOT)) {
      PrintFormat("increasing risk to meet min lot size: %.2f (was %.2f)", MarketInfo(Symbol(),MODE_MINLOT), lots);
      lots = MarketInfo(Symbol(),MODE_MINLOT);
   }
   if (tracelevel>=2) PrintFormat("money to risk: %.2f,stopDistance:%.5f, lotsize: %.2f, lots=%.2f",equityAtRisk,stopDistance,MarketInfo(Symbol(),MODE_LOTSIZE),lots);
   
   return lots;   
}

void trail() {
   if (trailingStopPoints == 0) return;  
   if (longTicket != -1 && OrderSelect(longTicket,SELECT_BY_TICKET)) {
      double stop = NormalizeDouble(Bid - (trailingStopPoints*_Point), _Digits);
      if (OrderStopLoss() < stop && OrderOpenPrice() < stop) {
         OrderModify(longTicket,OrderOpenPrice(),stop,OrderTakeProfit(),0,clrGreen);
      }
   }
   
   if (shortTicket != -1 && OrderSelect(shortTicket,SELECT_BY_TICKET)) {
      double stop = NormalizeDouble(Ask + (trailingStopPoints*_Point), _Digits);
      if (OrderStopLoss() > stop && OrderOpenPrice() > stop) {
         OrderModify(shortTicket,OrderOpenPrice(),stop,OrderTakeProfit(),0,clrRed);
      }
   }
      
}