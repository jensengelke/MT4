//{ ACR, Getxxx, Analyze
#define ACR_TIME     0  // Array Copy Rates
#define ACR_OPEN     1
#define ACR_LOW      2
#define ACR_HIGH     3
#define ACR_CLOSE    4
#define ACR_VOLUME   5
   #define ACR_COUNT    6
//+------------------------------------------------------------------+
//| Analyze Charts                                                   |
//+------------------------------------------------------------------+
void     OnInitAnalyze(){
   //{http://forum.mql4.com/36470/page2 says ArrayCopyRates is a nonreentrant,
   // non-thread-safe call. Therefor you must put a mutex around the call in
   // case of multiple EAs on multiple charts. Alteratively, since init() is
   // single threaded across all charts, put all ACRs there.
   //}
   ArrayCopyRates(acr.arr, market.pair, period.market);     // I'm in an OnInit.
}  // OnInitAnalyze
//+------------------------------------------------------------------+
//| Median values                                                    |
//+------------------------------------------------------------------+
//{ TheilSend, median, NthElement, Masar
void TheilSen2D(double& m, double& b, double v[][], int n1, int e2, int iBeg=0){
   //{Theil–Sen estimator of a set of two-dimensional points (xi,yi) is the
   // median m of the slopes (yj - yi)/(xj - xi)
   // http://en.wikipedia.org/wiki/Theil-Sen_estimator
   // 2     2:1                                                 1
   // 3     2:1, 3:1, 3:2                                       3
   // 4     2:1, 3:1, 3:2, 4:1, 4:2, 4:3                        6
   //}5     2:1, 3:1, 3:2, 4:1, 4:2, 4:3  5:1, 5:2, 5:3, 5:4   10
   static double slopes[];    int nReq = n1 * (n1-1) / 2;
   if(ArraySize(slopes) < nReq) if(ArrayResize(slopes, nReq) <= 0){
      DisableTrading("ArrayResize(TheilSen, " + nReq + ") Failed: "
                                                +GetLastError() );   return;  }
   int   nSlopes = 0;
   for(int i=iBeg + n1 - 1; i >  iBeg; i--)
      for (int j=i - 1;     j >= iBeg; j--){
         slopes[nSlopes] = (v[i][e2] - v[j][e2]) / (i-j);   nSlopes++;        }
   m = Median(slopes, nSlopes);
   for(i=0; i < n1; i++)   slopes[i] = v[iBeg+i][e2] - m * i;
   b = Median(slopes, n1);
}
double   Median(double& values[], int iLimit, int iBeg=0){
   int      iLeft = iBeg,  nValues = iLimit-iBeg,  iMed = iBeg + nValues / 2;
   double   med   = NthElement(values, iLeft, iMed, iLimit);
   if (nValues % 2 == 1)   return(med);                  // [0,1,(2),3,4]    N=5
   iLimit = iMed;    iMed--;                             // [0,1,2,(3),4,5]  N=6
   if(iLeft == iMed){   med += values[iMed];             // 0,1,[2,]3,4,5
                        return( med * 0.5 );                                  }
   if(iLeft > iMed)     iLeft = iBeg;                    // [0,1,2,]3,4,5
   med += NthElement(values, iLeft, iMed, iLimit);       // [0,1,(2),]3,4,5
   return( med * 0.5 );
}
#define ASCENDING    +1
#define DESCENDING   -1
double   NthElement(double&values[], int&iLB, int iNth, int&iRL, double asc=+1){
   //{Modified from https://github.com/romanows/QuickSelect
   // During the QuickSelect process, we often partially sort the array several
   // times before finding the selected element. Left Bound / Right Limit index
   // returned is the closest fixed pivot point encountered to the iNth. This is
   // mainly useful when running the median calculation on an even-length array,
   //}so the second middle point can be computed quickly.
   if(iLB > iNth || iNth >= iRL)    AssertFailure(
                  "nTh("+iLB+", "+iNth+", "+iRL+", "+SDoubleToString(asc)+")");
   while(true){   // Pick a pivot value: mid, Nth, median(Left, Right, Nth) ..
      int      iRight = iRL - 1;                            // Right inclusive.
      if(iLB >= iNth && iRight <= iNth)   return( values[iNth] );
      int      iPivot   = (iLB+iRight) / 2;                       // 321 312 231
      if((values[iLB]  - values[iRight])*asc > 0)
                                 SwapAD(values, iLB,  iRight);    // 123 213 132
      if((values[iLB]  - values[iPivot])*asc > 0)
                                 SwapAD(values, iLB,  iPivot);    //     123
      if((values[iPivot] - values[iRight])*asc > 0)
                                 SwapAD(values, iPivot, iRight);  //         123
      double   vPivot   = values[iPivot]; // unnecessary to store
      values[iPivot]    = values[iRight]; // values[iRight]=values[iPivot];

      // Ascending: Find first v[store] larger than v[pivot]
      for(int iStore=iLB; iStore < iRight; iStore++){
         double vStore = values[iStore];  if((vStore-vPivot)*asc > 0.)  break; }

      // Asscending: Find next v[test] smaller than v[pivot]
      for(int iTest=iStore+1; iTest < iRight; iTest++){
         double   vTest = values[iTest];  if((vTest - vPivot)*asc < 0.){
            values[iStore] = vTest;                   // Larger before.
            values[iTest]  = vStore;                  // Smaller after.
            iStore++;      vStore = values[iStore];   // Next store position.
      }  }
      values[iRight] = vStore;                        // Swap the pivot back to
      values[iStore] = vPivot;                        // the correct location.

      if(      iStore < iNth) iLB = iStore + 1;
      else  if(iStore > iNth) iRL = iStore;
      else                    return( values[iNth] );
   }  // while
   // NOTREACHED
}  // NthElement
void     SwapAD(double& arr[], int iA, int iB){
   double   T = arr[iA];   arr[iA] = arr[iB];   arr[iB] = T;                  }
