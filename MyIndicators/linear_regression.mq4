//+------------------------------------------------------------------+
//|                                            Linear Regression.mq4 |
//|                Copyright © 2006, tageiger, aka fxid10t@yahoo.com |
//|                                        http://www.metaquotes.net |
//+------------------------------------------------------------------+
#property copyright "Copyright © 2006, tageiger, aka fxid10t@yahoo.com"
#property link      "http://www.metaquotes.net"
#property indicator_chart_window

extern int period=0;
/*default 0 means the channel will use the open time from "x" bars back on which ever time period 
the indicator is attached to.  one can change to 1,5,15,30,60...etc to "lock" the start time to a specific 
period, and then view the "locked" channels on a different time period...*/
extern int line.width=2;
extern int LR.length=34;   // bars back regression begins
extern color  LR.c=Orange;
extern double std.channel.1=0.618;        // 1st channel
extern color  c.1=Gray;
extern double std.channel.2=1.618;        // 2nd channel
extern color  c.2=Gray;
extern double std.channel.3=2.618;        // 3nd channel
extern color  c.3=Gray;

int init(){return(0);}

int deinit(){ ObjectDelete(period+"m "+LR.length+" TL"); 
   ObjectDelete(period+"m "+LR.length+" +"+std.channel.1+"d"); ObjectDelete(period+"m "+LR.length+" -"+std.channel.1+"d");
   ObjectDelete(period+"m "+LR.length+" +"+std.channel.2+"d"); ObjectDelete(period+"m "+LR.length+" -"+std.channel.2+"d");
   ObjectDelete(period+"m "+LR.length+" +"+std.channel.3+"d"); ObjectDelete(period+"m "+LR.length+" -"+std.channel.3+"d");
return(0);}

int start(){//refresh chart
ObjectDelete(period+"m "+LR.length+" TL");
ObjectDelete(period+"m "+LR.length+" +"+std.channel.1+"d"); ObjectDelete(period+"m "+LR.length+" -"+std.channel.1+"d");
ObjectDelete(period+"m "+LR.length+" +"+std.channel.2+"d"); ObjectDelete(period+"m "+LR.length+" -"+std.channel.2+"d");
ObjectDelete(period+"m "+LR.length+" +"+std.channel.3+"d"); ObjectDelete(period+"m "+LR.length+" -"+std.channel.3+"d");
//linear regression calculation
int start.bar=LR.length, end.bar=0;
   int n=start.bar-end.bar+1;
//---- calculate price values
   double value=iClose(Symbol(),period,end.bar);
   double a,b,c;
   double sumy=value;
   double sumx=0.0;
   double sumxy=0.0;
   double sumx2=0.0;
   for(int i=1; i<n; i++)
     {
      value=iClose(Symbol(),period,end.bar+i);
      sumy+=value;
      sumxy+=value*i;
      sumx+=i;
      sumx2+=i*i;
     }
   c=sumx2*n-sumx*sumx;
   if(c==0.0) return;
   b=(sumxy*n-sumx*sumy)/c;
   a=(sumy-sumx*b)/n;
   double LR.price.2=a;
   double LR.price.1=a+b*n;

//---- maximal deviation calculation (not used)
   double max.dev=0;
   double deviation=0;
   double dvalue=a;
   for(i=0; i<n; i++)
     {
      value=iClose(Symbol(),period,end.bar+i);
      dvalue+=b;
      deviation=MathAbs(value-dvalue);
      if(max.dev<=deviation) max.dev=deviation;
     }
//Linear regression trendline
   ObjectCreate(period+"m "+LR.length+" TL",OBJ_TREND,0,iTime(Symbol(),period,start.bar),LR.price.1,Time[end.bar],LR.price.2);
   ObjectSet(period+"m "+LR.length+" TL",OBJPROP_COLOR,LR.c);
   ObjectSet(period+"m "+LR.length+" TL",OBJPROP_WIDTH,line.width);
   ObjectSet(period+"m "+LR.length+" TL",OBJPROP_RAY,false);     
//...standard deviation...
   double x=0,x.sum=0,x.avg=0,x.sum.squared=0,std.dev=0;
   for(i=0; i<start.bar; i++)    {
      x=MathAbs(iClose(Symbol(),period,i)-ObjectGetValueByShift(period+"m "+LR.length+" TL",i));
      x.sum+=x;
      if(i>0)  {
         x.avg=(x.avg+x)/i;
         x.sum.squared+=(x-x.avg)*(x-x.avg);
         std.dev=MathSqrt(x.sum.squared/(start.bar-1));  }  }
   //Print("LR.price.1 ",LR.price.1,"  LR.Price.2 ",LR.price.2," std.dev ",std.dev);
//...standard deviation channels...
   ObjectCreate(period+"m "+LR.length+" +"+std.channel.1+"d",OBJ_TREND,0,iTime(Symbol(),period,start.bar),LR.price.1+std.dev*std.channel.1,
                                        Time[end.bar],LR.price.2+std.dev*std.channel.1);
   ObjectSet(period+"m "+LR.length+" +"+std.channel.1+"d",OBJPROP_COLOR,c.1);
   ObjectSet(period+"m "+LR.length+" +"+std.channel.1+"d",OBJPROP_WIDTH,line.width);
   ObjectSet(period+"m "+LR.length+" +"+std.channel.1+"d",OBJPROP_RAY,false);
   
   ObjectCreate(period+"m "+LR.length+" -"+std.channel.1+"d",OBJ_TREND,0,iTime(Symbol(),period,start.bar),LR.price.1-std.dev*std.channel.1,
                                             Time[end.bar],LR.price.2-std.dev*std.channel.1);
   ObjectSet(period+"m "+LR.length+" -"+std.channel.1+"d",OBJPROP_COLOR,c.1);
   ObjectSet(period+"m "+LR.length+" -"+std.channel.1+"d",OBJPROP_WIDTH,line.width);
   ObjectSet(period+"m "+LR.length+" -"+std.channel.1+"d",OBJPROP_RAY,false);

   ObjectCreate(period+"m "+LR.length+" +"+std.channel.2+"d",OBJ_TREND,0,iTime(Symbol(),period,start.bar),LR.price.1+std.dev*std.channel.2,
                                             Time[end.bar],LR.price.2+std.dev*std.channel.2);
   ObjectSet(period+"m "+LR.length+" +"+std.channel.2+"d",OBJPROP_COLOR,c.2);
   ObjectSet(period+"m "+LR.length+" +"+std.channel.2+"d",OBJPROP_WIDTH,line.width);
   ObjectSet(period+"m "+LR.length+" +"+std.channel.2+"d",OBJPROP_RAY,false);
   
   ObjectCreate(period+"m "+LR.length+" -"+std.channel.2+"d",OBJ_TREND,0,iTime(Symbol(),period,start.bar),LR.price.1-std.dev*std.channel.2,
                                             Time[end.bar],LR.price.2-std.dev*std.channel.2);
   ObjectSet(period+"m "+LR.length+" -"+std.channel.2+"d",OBJPROP_COLOR,c.2);
   ObjectSet(period+"m "+LR.length+" -"+std.channel.2+"d",OBJPROP_WIDTH,line.width);
   ObjectSet(period+"m "+LR.length+" -"+std.channel.2+"d",OBJPROP_RAY,false);

   ObjectCreate(period+"m "+LR.length+" +"+std.channel.3+"d",OBJ_TREND,0,iTime(Symbol(),period,start.bar),LR.price.1+std.dev*std.channel.3,
                                             Time[end.bar],LR.price.2+std.dev*std.channel.3);
   ObjectSet(period+"m "+LR.length+" +"+std.channel.3+"d",OBJPROP_COLOR,c.3);
   ObjectSet(period+"m "+LR.length+" +"+std.channel.3+"d",OBJPROP_WIDTH,line.width);
   ObjectSet(period+"m "+LR.length+" +"+std.channel.3+"d",OBJPROP_RAY,false);
   
   ObjectCreate(period+"m "+LR.length+" -"+std.channel.3+"d",OBJ_TREND,0,iTime(Symbol(),period,start.bar),LR.price.1-std.dev*std.channel.3,
                                             Time[end.bar],LR.price.2-std.dev*std.channel.3);
   ObjectSet(period+"m "+LR.length+" -"+std.channel.3+"d",OBJPROP_COLOR,c.3);
   ObjectSet(period+"m "+LR.length+" -"+std.channel.3+"d",OBJPROP_WIDTH,line.width);
   ObjectSet(period+"m "+LR.length+" -"+std.channel.3+"d",OBJPROP_RAY,false);
      
return(0);}
//+------------------------------------------------------------------+