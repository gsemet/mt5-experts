//+------------------------------------------------------------------+
//|                                                       dax-v1.mq5 |
//|                                            Copyright 2014, Stibb |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2014, Stibb"
#property link      "http://www.mql5.com"
#property version   "1.00"


//+------------------------------------------------------------------+
//| Include                                                          |
//+------------------------------------------------------------------+
#include <Expert\Expert.mqh>
//--- available signals
#include <Expert\Signal\SignalCrossEMA.mqh>
#include <Expert\Signal\SignalMA.mqh>
//--- available trailing
#include <Expert\Trailing\TrailingNoLose.mqh>
//--- available money management
#include <Expert\Money\MoneyFixedRisk.mqh>


//+------------------------------------------------------------------+
//| Inputs                                                           |
//+------------------------------------------------------------------+

//--- inputs for expert
input string             Expert_Title                     = "dax-v1";   // Document name
ulong                    Expert_MagicNumber               = 27163;      // 
bool                     Expert_EveryTick                 = true;      //

//--- inputs for signal
input int                Inp_Signal_CrossEMA_FastPeriod   = 6;
input int                Inp_Signal_CrossEMA_SlowPeriod   = 20;
input int                Inp_Signal_CrossEMA_StopLoss     = 30;
input int                Inp_Signal_Min_Win               = 10; // Minimal win.
input int                Inp_Never_Loose_Money            = true;  // If true, never loose money

//--- inputs for trailing
input int                Trailing_NoLose_StopLevel            = 30;     // Stop Loss trailing level (in points)
input int                Trailing_NoLose_RetracementThreshold = 100;    // Min threshold to start retracement count (in points)
input int                Trailing_NoLose_AllowedRetracement   = 50;     // Allowed Retracement (in percentage)

//--- inputs for money
input double             Money_FixLot_Percent             = 0.02;       // Percent


//+------------------------------------------------------------------+
//| Global expert object                                             |
//+------------------------------------------------------------------+
CExpert ExtExpert;


//+------------------------------------------------------------------+
//| Initialization function of the expert                            |
//+------------------------------------------------------------------+
int OnInit()
{
    //--- Initializing expert
    if (!ExtExpert.Init(Symbol(), PERIOD_M1, Expert_EveryTick, Expert_MagicNumber))
    {
        //--- failed
        printf(__FUNCTION__ + ": error initializing expert");
        ExtExpert.Deinit();
        return(INIT_FAILED);
    }
    
    //--- Creation of signal object
    CSignalCrossEMA * signal = new CSignalCrossEMA;
    if(signal==NULL)
    {
        //--- failed
        printf(__FUNCTION__ + ": error creating signal");
        ExtExpert.Deinit();
        return(-2);
    }
    
    //--- Add signal to expert (will be deleted automatically))
    if(!ExtExpert.InitSignal(signal))
    {
        //--- failed
        printf(__FUNCTION__ + ": error initializing signal");
        ExtExpert.Deinit();
        return(-3);
    }

    //--- Set signal parameters
    signal.FastPeriod(Inp_Signal_CrossEMA_FastPeriod);
    signal.SlowPeriod(Inp_Signal_CrossEMA_SlowPeriod);
    signal.StopLevel(Inp_Signal_CrossEMA_StopLoss);
    signal.RetracementThreshold(Trailing_NoLose_RetracementThreshold);
    signal.AllowedRetracement(Trailing_NoLose_AllowedRetracement);
    signal.MinWin(Inp_Signal_Min_Win);
    signal.EnableNeverLooseMoney(Inp_Never_Loose_Money);
   
    //--- Check signal parameters
    if (!signal.ValidationSettings())
    {
        //--- failed
        printf (__FUNCTION__ + ": error signal parameters");
        ExtExpert.Deinit();
        return (-4);
    }
    
    //--- Creating filter CSignalMA
    //CSignalMA *filter0 = new CSignalMA;
    //if (filter0 == NULL)
    //{
    //    //--- failed
    //    printf(__FUNCTION__ + ": error creating filter 'reintegration filter'");
    //    ExtExpert.Deinit();
    //    return(INIT_FAILED);
    //}

    //signal.AddFilter(filter0);
    //--- Set filter parameters
    //filter0.PeriodMA(Inp_Signal_CrossEMA_SlowPeriod);
    //filter0.Shift(0);
    //filter0.Method(MODE_EMA);
    //filter0.Applied(PRICE_CLOSE);
    //filter0.Weight(1.0);

    //--- Creation of trailing object
    CTrailingNoLose *trailing = new CTrailingNoLose;
    if (trailing == NULL)
    {
        //--- failed
        printf(__FUNCTION__ + ": error creating trailing");
        ExtExpert.Deinit();
        return(INIT_FAILED);
    }

    //--- Add trailing to expert (will be deleted automatically))
    if (!ExtExpert.InitTrailing(trailing))
    {
        //--- failed
        printf(__FUNCTION__ + ": error initializing trailing");
        ExtExpert.Deinit();
        return(INIT_FAILED);
    }
     
    //--- Set trailing parameters
    trailing.StopLevel(Trailing_NoLose_StopLevel);
    trailing.RetracementThreshold(Trailing_NoLose_RetracementThreshold);
    trailing.AllowedRetracement(Trailing_NoLose_AllowedRetracement);
    trailing.MinWin(Inp_Signal_Min_Win);
    
    //--- Check trailing parameters
    if(!trailing.ValidationSettings())
    {
        //--- failed
        printf(__FUNCTION__ + ": error trailing parameters");
        ExtExpert.Deinit();
        return(-7);
    }

    //--- Creation of money object
    CMoneyFixedRisk *money = new CMoneyFixedRisk;
    if (money == NULL)
    {
        //--- failed
        printf(__FUNCTION__ + ": error creating money");
        ExtExpert.Deinit();
        return(INIT_FAILED);
    }
    
    //--- Add money to expert (will be deleted automatically))
    if (!ExtExpert.InitMoney(money))
    {
        //--- failed
        printf(__FUNCTION__ + ": error initializing money");
        ExtExpert.Deinit();
        return(INIT_FAILED);
    }
    
    //--- Set money parameters
    money.Percent(Money_FixLot_Percent);

    //--- Check money parameters
    if(!money.ValidationSettings())
    {
        //--- failed
        printf(__FUNCTION__ + ": error money parameters");
        ExtExpert.Deinit();
        return(-10);
    }
     
    //--- Check all trading objects parameters
    if (!ExtExpert.ValidationSettings())
    {
        //--- failed
        ExtExpert.Deinit();
        return(INIT_FAILED);
    }

    //--- Tuning of all necessary indicators
    if (!ExtExpert.InitIndicators())
    {
        //--- failed
        printf(__FUNCTION__ + ": error initializing indicators");
        ExtExpert.Deinit();
        return(INIT_FAILED);
    }
    
    //--- ok
    return(INIT_SUCCEEDED);
}


//+------------------------------------------------------------------+
//| Deinitialization function of the expert                          |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
    ExtExpert.Deinit();
}


//+------------------------------------------------------------------+
//| "Tick" event handler function                                    |
//+------------------------------------------------------------------+
void OnTick()
{
    // printf(__FUNCTION__ + ": on tick !");
    ExtExpert.OnTick();
}


//+------------------------------------------------------------------+
//| "Trade" event handler function                                   |
//+------------------------------------------------------------------+
void OnTrade()
{
    // printf(__FUNCTION__ + ": Trade triggered !");
    ExtExpert.OnTrade();
}


//+------------------------------------------------------------------+
//| "Timer" event handler function                                   |
//+------------------------------------------------------------------+
void OnTimer()
{
    // printf(__FUNCTION__ + ": on timer !");
    ExtExpert.OnTimer();
}
//+------------------------------------------------------------------+
