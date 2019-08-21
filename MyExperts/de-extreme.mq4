//+------------------------------------------------------------------+
//|                                                   de-extreme.mq4 |
//|                                                       de-extreme |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "de-extreme"
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

double lastClose = 0.0;
double rsiLowThreshold = 0.0;
double rsiHighThreshold = 0.0;
int lotDigits = 0;

extern int myMagic = 20190629;
extern int rsiPeriod = 8;
extern double rsiThreshold = 15.0;
extern double risk = 2.0;
extern double initialStopStdDevFact = 2.5;
extern double initialStop = 50.0; //ignored when working with StdDev
extern double trailingStopInProfit = 50.0;
extern int tracelevel = 0;


//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
   if (rsiThreshold >= 50.0) return(INIT_PARAMETERS_INCORRECT);
   rsiLowThreshold = rsiThreshold;
   rsiHighThreshold = 100 - rsiThreshold;
   
   double lotStep = MarketInfo(_Symbol,MODE_LOTSTEP);
   PrintFormat("I0001: lotstep = %.5f", lotStep);
   lotDigits = MathLog(1/lotStep)/MathLog(10);
   PrintFormat("I0002: lotDigits = %f %d %i", lotDigits, lotDigits, lotDigits);
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
   if (Close[1] == lastClose) return;
   
   lastClose = Close[1];
   trail();
   
   double rsi1 = iRSI(_Symbol,PERIOD_CURRENT,rsiPeriod,PRICE_CLOSE,1);
   double rsi2 = iRSI(_Symbol,PERIOD_CURRENT,rsiPeriod,PRICE_CLOSE,2);
   
   if (rsi2 < rsiLowThreshold && rsi1 > rsiLowThreshold) buy();
   if (rsi2 > rsiHighThreshold && rsi1 < rsiHighThreshold) sell();
   
  }
//+------------------------------------------------------------------+

void buy() {
   if (initialStopStdDevFact > 0.0) initialStop = initialStopStdDevFact * iStdDev(_Symbol,PERIOD_CURRENT,rsiPeriod,0,MODE_EMA,PRICE_MEDIAN,1);
   double stop = Ask - initialStop;
   double tp = 0.0;
   double lots = lotsByRisk( MathAbs(Ask - stop), risk);
   if (!OrderSend(_Symbol,OP_BUY,lots,Ask,10,stop,0,"deeskalation",myMagic,0,clrGreen)) {
      PrintFormat("E001: cannot buy");
   }
}

void sell() {
   if (initialStopStdDevFact > 0.0) initialStop = initialStopStdDevFact * iStdDev(_Symbol,PERIOD_CURRENT,rsiPeriod,0,MODE_EMA,PRICE_MEDIAN,1);
   double stop = Bid + initialStop;
   double tp = 0.0;
   double lots = lotsByRisk( MathAbs(stop - Bid), risk);
   if (!OrderSend(_Symbol,OP_SELL,lots,Bid,10,stop,0,"deeskalation",myMagic,0,clrGreen)) {
      PrintFormat("E002: cannot sell");
   }
}

void trail() {
   

   double stopForLong = Bid - trailingStopInProfit;
   double stopForShort = Ask + trailingStopInProfit;
   bool inProfit = true;
   
   for (int i=OrdersTotal();i>=0;i--) {
      if (OrderSelect(i,SELECT_BY_POS,MODE_TRADES)) {
         
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
}

double lotsByRisk(double stopDistance, double riskInPercentOfEquity) {
   if (tracelevel>=2) PrintFormat("ENTRY lotsByRisk [stopDistance: %.5f, riskInPercentOfEquity: %.2f", stopDistance, riskInPercentOfEquity);
   if (0==stopDistance) return 0.0;
   //PrintFormat("passed symbol_digits=%i, mode_points says: %i",lotDigits, MarketInfo(Symbol(),MODE_DIGITS));
   double equityAtRisk = (riskInPercentOfEquity/100) * AccountEquity();
   //PrintFormat("equity to risk: %.2f with stopDistance=%.2f",equityAtRisk,stopDistance);
   double lots = equityAtRisk / (stopDistance * MarketInfo(Symbol(),MODE_LOTSIZE));
   if (tracelevel>=2) PrintFormat("lots by risk: %.2f, lotsize: %.2f", lots, MarketInfo(Symbol(),MODE_LOTSIZE));
   double marginPerLot = 600.0; // MarketInfo(_Symbol,MODE_MARGININIT);
   double freeMargin = AccountFreeMargin();
   
   if ( (freeMargin/lots) < marginPerLot) lots = freeMargin/marginPerLot;
   
   if (tracelevel >= 2) PrintFormat("freeMargin: %.2f, marinPerLot: %.2f",freeMargin,marginPerLot);
   
   lots = NormalizeDouble(lots,lotDigits);
   
   if (lots > MarketInfo(Symbol(),MODE_MAXLOT)) {
      lots = MarketInfo(Symbol(),MODE_MAXLOT);
   }
   if (lots < MarketInfo(Symbol(),MODE_MINLOT)) {
      PrintFormat("increasing risk to meet min lot size: %.2f (was %.2f)", MarketInfo(Symbol(),MODE_MINLOT), lots);
      lots = MarketInfo(Symbol(),MODE_MINLOT);
   }
   
   
   if (tracelevel >= 1) PrintFormat("money to risk: %.2f,stopDistance:%.2f, lotsize: %.2f, lots=%.2f",equityAtRisk,stopDistance,MarketInfo(Symbol(),MODE_LOTSIZE),lots);
   
   return lots;   
}
