//+------------------------------------------------------------------+
//|                                                     Swissbox.mq4 |
//|                                                          DerJens |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "DerJens"
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

static datetime lastBar = NULL;
static datetime boxOpenTime = NULL;

input string boxOpen = "08:54";
input int    lookBackBars = 54;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {

   boxOpenTime = StrToTime(boxOpen);
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {

   
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {

   if (Time[0] == lastBar) return;
   
   lastBar = Time[0];
   
   if (TimeCurrent() == boxOpenTime) {
      double high = High[iHighest(_Symbol,PERIOD_CURRENT,MODE_HIGH,lookBackBars,0);
      double low  = Low[iLowest(_Symbol,PERIOD_CURRENT,MODE_LOW,lookBackBars,0);
      
      if ( (high-Ask) < (Bid - low) ) {  // am oberen Ende
      
         
      
      } else { // am unteren Ende
      
      }
   }
   
   
  }
//+------------------------------------------------------------------+
