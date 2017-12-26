//+------------------------------------------------------------------+
//|                                                  Jens-ROC-MA.mq4 |
//|                                 Rate Of Change of Moving Average |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Rate Of Change of Moving Average"
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict
#property indicator_separate_window

extern int period = 50;

int maxHistory = 5000;
double indicatorLine[];
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
   IndicatorBuffers(1);
   SetIndexStyle(0,DRAW_HISTOGRAM, STYLE_SOLID,2,clrYellow);
   
   SetIndexBuffer(0,indicatorLine); 
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
  {
   double maPrevious = 0.0;
   int i = IndicatorCounted() -1;
   if (i>maxHistory-1) {
      i = maxHistory-1;
   }
   
   
   while (i>=0) {
      if (maPrevious == 0.0) {
         maPrevious = iMA(NULL,PERIOD_CURRENT,period,0,MODE_SMA,PRICE_CLOSE,i-1);
      }
      double maCurrent = iMA(NULL,PERIOD_CURRENT,period,0,MODE_SMA,PRICE_CLOSE,i);
      if (maPrevious!=0.0) {
         indicatorLine[i] = maCurrent / maPrevious;
      } else {
         indicatorLine[i] = -1;
      }
      
      maPrevious = maCurrent;
      i--;
   }

   return(rates_total);
   
  }
//+------------------------------------------------------------------+
