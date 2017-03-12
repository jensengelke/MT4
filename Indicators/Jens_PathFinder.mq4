//+------------------------------------------------------------------+
//|                                                        Bands.mq4 |
//|                   Copyright 2005-2014, MetaQuotes Software Corp. |
//|                                              http://www.mql4.com |
//+------------------------------------------------------------------+
#property copyright   "2005-2014, MetaQuotes Software Corp."
#property link        "http://www.mql4.com"
#property description "pathfinder"
#property strict



#property indicator_chart_window
#property indicator_buffers 3
#property indicator_color1 LightSeaGreen
#property indicator_color2 LightSeaGreen
#property indicator_color3 LightSeaGreen

//--- buffers
double dHigh[];
double dLow[];
double wHigh[];
double wLow[];
double mHigh[];
double mLow[];

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit(void)
  {

   IndicatorBuffers(6);
   IndicatorDigits(Digits);

   SetIndexStyle(0,DRAW_LINE,STYLE_SOLID,3,clrGreen);
   SetIndexBuffer(0,dHigh);
   
   SetIndexStyle(1,DRAW_LINE,STYLE_SOLID,3,clrRed);
   SetIndexBuffer(1,dLow);
   
   SetIndexStyle(2,DRAW_LINE,STYLE_DOT,2,clrGreen);
   SetIndexBuffer(2,wHigh);
   
   SetIndexStyle(3,DRAW_LINE,STYLE_DOT,2,clrRed);
   SetIndexBuffer(3,wLow);
   
   SetIndexStyle(4,DRAW_LINE,STYLE_DASH,1,clrGreen);
   SetIndexBuffer(4,mHigh);
   
   SetIndexStyle(5,DRAW_LINE,STYLE_DASH,1,clrRed);
   SetIndexBuffer(5,mLow);

   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Bollinger Bands                                                  |
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
   int i,pos;
   double dayHigh, lastDayHigh, weekHigh, lastWeekHigh, monthHigh, lastMonthHigh;
   double dayLow, lastDayLow, weekLow, lastWeekLow, monthLow, lastMonthLow;   
   int currDay,currWeek,currMonth;
   /*
   ArraySetAsSeries(dHigh,false);
   ArraySetAsSeries(dLow,false);
   ArraySetAsSeries(wHigh,false);
   ArraySetAsSeries(wLow,false);
   ArraySetAsSeries(mHigh,false);
   ArraySetAsSeries(mLow,false);
   */
   if (prev_calculated<1) {
      currDay = currWeek = currMonth =-1;
   }
   
   if(prev_calculated>1)
      pos=prev_calculated;
   else
      pos=0;

   for(i=rates_total-1; i>=pos && !IsStopped(); i--) {
      if (TimeDay(Time[i]) != currDay){
         lastDayHigh = dayHigh;
         lastDayLow = dayLow;
         dayHigh = 0;
         dayLow = High[i]*1000;    
         currDay = TimeDay(Time[i]);     
      }
      
      if (TimeDay(Time[i])%7 != currWeek){
         lastWeekHigh = weekHigh;
         lastWeekLow = weekLow;
         weekHigh = 0;
         weekLow = High[i]*1000;      
         currWeek = TimeDay(Time[i])%7 ;  
      }
      
      if (TimeMonth(Time[i]) != currMonth){
         lastMonthHigh = monthHigh;
         lastMonthLow = monthLow;
         monthHigh = 0;
         monthLow = High[i]*1000;     
         currMonth = TimeMonth(Time[i]);
      }
      
      
      if (High[i]>dayHigh) dayHigh = High[i];
      if (High[i]>weekHigh) weekHigh = High[i];
      if (High[i]>monthHigh) monthHigh = High[i];
      if (Low[i]<dayLow) dayLow = Low[i];
      if (Low[i]<weekLow) weekLow = Low[i];
      if (Low[i]<monthLow) monthLow = Low[i];
      
     
      //--- middle line
      dHigh[i]    = lastDayHigh;
      dLow[i]     = lastDayLow;
      wHigh[i]    = lastWeekHigh;
      wLow[i]     = lastWeekLow;
      mHigh[i]    = lastMonthHigh;
      mLow[i]     = lastMonthLow;
      
     }
//---- OnCalculate done. Return new prev_calculated.
   return(rates_total);
  }
