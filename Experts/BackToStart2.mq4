//+------------------------------------------------------------------+
//|                                                  BackToStart.mq4 |
//|                                                      backToStart |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "backToStart2"
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict
#include "../Include/JensUtils.mqh";
extern int myMagic = 201700716;

extern string openRangeStart = "08:00";
extern string openRangeEnd = "08:45";
extern string flatAfter = "09:15";
extern double maxRange = 80.0;
extern double risk = 1.0;
extern int numberOfPositions = 3;
extern double distance = 10.0;
extern bool trace = true;

static datetime lastTradeTime = NULL;
static int symbolDigits = -1;
static int lotDigits = -1;

int grid_orders[]; //state [0...init; 1..price determined; 2..opened; 3..canceled]
double grid_prices[];
double openRangeStartPrice = 0.0;
datetime openRangeStartTime = NULL;
datetime openRangeEndTime  = NULL;
datetime flatAfterTime = NULL;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- create timer
   EventSetTimer(60);
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
   
   ArrayResize(grid_orders,2*numberOfPositions,1);
   ArrayResize(grid_prices,2*numberOfPositions,1);
   ArrayFill(grid_orders,0,ArrayRange(grid_orders,0),0);
   ArrayFill(grid_prices,0,ArrayRange(grid_prices,0),0.0);
   return(INIT_SUCCEEDED);
  }

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//--- destroy timer
   EventKillTimer();
      
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//---
   if(DayOfWeek()==0 || DayOfWeek()==6) return;
   
   if (TimeCurrent() == lastTradeTime) {
      return;
   }
   lastTradeTime = TimeCurrent();
   
   int hour = TimeHour(TimeLocal());
   int min  = TimeMinute(TimeLocal());
   
   if (NULL == openRangeStartTime) {
      openRangeStartTime = todayAt(openRangeStart);
      openRangeEndTime = todayAt(openRangeEnd);
      flatAfterTime = todayAt(flatAfter);
   }
   
   datetime now = TimeLocal();
   if (now < openRangeStartTime) return;
   if (now > flatAfterTime) {
      if (openRangeStartTime != NULL) {
         closeAllOpenOrders(myMagic);
         closeAllPendingOrders(myMagic);
         ArrayFill(grid_orders,0,ArrayRange(grid_orders,0),0);
         ArrayFill(grid_prices,0,ArrayRange(grid_orders,0),0.0);
         openRangeStartTime = NULL;
         openRangeEndTime = NULL;
         flatAfterTime = NULL;
         openRangeStartPrice = 0.0;
      }
      return;
   }
   
   if (now > openRangeStartTime && now < openRangeEndTime) {
      if (grid_orders[0] == 0) {
         openRangeStartPrice = Ask;
         for (int i=0;i<numberOfPositions;i++) {
            grid_orders[i] = 1;
            grid_prices[i] = NormalizeDouble(openRangeStartPrice + ((i+1)*distance),symbolDigits);
            grid_orders[i+numberOfPositions] = 1;
            grid_prices[i+numberOfPositions] = NormalizeDouble(openRangeStartPrice -((i+1)*distance),symbolDigits);         
            PrintFormat("grid_prices[%i]=%.2f ; grid_prices[%i]=%.2f",i,grid_prices[i],(i+numberOfPositions),grid_prices[i+numberOfPositions]);
         }
         
      } else {
         // open positions
         
         if (Ask > openRangeStartPrice + (numberOfPositions*distance)) { // short
            for (int i=0;i<numberOfPositions;i++) {
               if (grid_orders[i] == 1 && Ask > grid_prices[i]+distance) {
                  double shortStop = NormalizeDouble(grid_prices[i]+2*distance,symbolDigits);
                  double shortPrice = NormalizeDouble(grid_prices[i],symbolDigits);
                  double shortLots = lotsByRisk( (shortStop - shortPrice), NormalizeDouble(risk/numberOfPositions,2),lotDigits);
                  
                  if (trace) {
                     PrintFormat("stop sell: Ask=%.2f, price=%.2f,stop=%.2f,tp=%.2f,lots=%.2f",Ask,shortPrice,shortStop,openRangeStartPrice,shortLots);
                  }
                  OrderSend(Symbol(),OP_SELLSTOP,shortLots,shortPrice,3,shortStop,openRangeStartPrice,"back to start "+i,myMagic,0,clrGreen);
                  grid_orders[i]=2;
               }
            }
         
         }
         
         if (Ask < openRangeStartPrice - (numberOfPositions *distance)) { // long
            for (int i=0;i<numberOfPositions;i++) {
               if (grid_orders[numberOfPositions+i] == 1 && Ask < (grid_prices[numberOfPositions+i]-distance)) {
                  double longStop = NormalizeDouble(grid_prices[i+numberOfPositions]-2*distance,symbolDigits);
                  double longPrice = NormalizeDouble(grid_prices[i+numberOfPositions],symbolDigits);
                  double longLots = lotsByRisk( longPrice-longStop, NormalizeDouble(risk/numberOfPositions,2),lotDigits);
                  if (trace) {
                     PrintFormat("stop buy: Ask=%.2f, price=%.2f,stop=%.2f,tp=%.2f,lots=%.2f",Ask,longPrice,longStop,openRangeStartPrice,longLots);
                  }
                  OrderSend(Symbol(),OP_BUYSTOP,longLots,longPrice,3,longStop,openRangeStartPrice,"back to start "+(numberOfPositions+i),myMagic,0,clrGreen);
                  grid_orders[numberOfPositions + i]=2;
               }
            }
         }
      }
      
   }   
  }
//+------------------------------------------------------------------+
//| Timer function                                                   |
//+------------------------------------------------------------------+
void OnTimer()
  {
//---
   
  }
//+------------------------------------------------------------------+
