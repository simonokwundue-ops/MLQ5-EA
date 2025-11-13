//+------------------------------------------------------------------+
//|                                              ForexTrader_EA.mq5 |
//|                                         Based on Forex Documents |
//|                              Advanced Trading Course Principles |
//+------------------------------------------------------------------+
#property copyright "ForexTrader EA"
#property link      ""
#property version   "1.00"
#property description "Expert Advisor based on Moving Average trading strategy"
#property description "Implements trend following with proper risk management"

//--- Input Parameters
input group "=== Trading Strategy Parameters ==="
input int      FastMA_Period = 10;           // Fast MA Period
input int      SlowMA_Period = 70;           // Slow MA Period
input ENUM_MA_METHOD MA_Method = MODE_SMA;   // Moving Average Method
input ENUM_APPLIED_PRICE MA_Price = PRICE_CLOSE; // Applied Price

input group "=== Risk Management ==="
input double   RiskPercent = 2.0;            // Risk per trade (% of balance)
input double   StopLossPips = 50.0;          // Stop Loss in Pips
input double   TakeProfitPips = 100.0;       // Take Profit in Pips
input bool     UseTrailingStop = true;       // Use Trailing Stop
input double   TrailingStopPips = 30.0;      // Trailing Stop Distance (Pips)
input double   TrailingStepPips = 10.0;      // Trailing Step (Pips)

input group "=== Money Management ==="
input double   MaxLotSize = 10.0;            // Maximum Lot Size
input double   MinLotSize = 0.01;            // Minimum Lot Size
input bool     UseFixedLot = false;          // Use Fixed Lot Size
input double   FixedLotSize = 0.1;           // Fixed Lot Size

input group "=== Trading Hours ==="
input bool     UseTradingHours = false;      // Limit Trading Hours
input int      StartHour = 8;                // Start Trading Hour
input int      EndHour = 20;                 // End Trading Hour

input group "=== Advanced Settings ==="
input int      MagicNumber = 123456;         // Magic Number
input string   TradeComment = "ForexTrader"; // Trade Comment
input int      Slippage = 10;                // Slippage in Points

//--- Global Variables
int handleFastMA;
int handleSlowMA;
double fastMA[], slowMA[];
double point;
int digits;
double tickSize;
double tickValue;
double lotStep;
double minLot;
double maxLot;

#include <Trade\Trade.mqh>
CTrade trade;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
   //--- Initialize trade object
   trade.SetExpertMagicNumber(MagicNumber);
   trade.SetDeviationInPoints(Slippage);
   trade.SetTypeFilling(ORDER_FILLING_FOK);
   
   //--- Get symbol properties
   point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
   digits = (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS);
   tickSize = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
   tickValue = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
   lotStep = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
   minLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   maxLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
   
   //--- Validate inputs
   if(FastMA_Period <= 0 || SlowMA_Period <= 0)
   {
      Print("Error: MA periods must be positive");
      return(INIT_PARAMETERS_INCORRECT);
   }
   
   if(FastMA_Period >= SlowMA_Period)
   {
      Print("Error: Fast MA period must be less than Slow MA period");
      return(INIT_PARAMETERS_INCORRECT);
   }
   
   if(RiskPercent <= 0 || RiskPercent > 100)
   {
      Print("Error: Risk percent must be between 0 and 100");
      return(INIT_PARAMETERS_INCORRECT);
   }
   
   //--- Create Moving Average indicators
   handleFastMA = iMA(_Symbol, PERIOD_CURRENT, FastMA_Period, 0, MA_Method, MA_Price);
   handleSlowMA = iMA(_Symbol, PERIOD_CURRENT, SlowMA_Period, 0, MA_Method, MA_Price);
   
   if(handleFastMA == INVALID_HANDLE || handleSlowMA == INVALID_HANDLE)
   {
      Print("Error creating MA indicators");
      return(INIT_FAILED);
   }
   
   //--- Set array as series
   ArraySetAsSeries(fastMA, true);
   ArraySetAsSeries(slowMA, true);
   
   Print("ForexTrader EA initialized successfully");
   Print("Fast MA Period: ", FastMA_Period);
   Print("Slow MA Period: ", SlowMA_Period);
   Print("Risk per trade: ", RiskPercent, "%");
   
   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   //--- Release indicator handles
   if(handleFastMA != INVALID_HANDLE)
      IndicatorRelease(handleFastMA);
   if(handleSlowMA != INVALID_HANDLE)
      IndicatorRelease(handleSlowMA);
      
   Print("ForexTrader EA deinitialized. Reason: ", reason);
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
   //--- Check if it's a new bar
   static datetime lastBar = 0;
   datetime currentBar = iTime(_Symbol, PERIOD_CURRENT, 0);
   
   if(currentBar == lastBar)
      return;
      
   lastBar = currentBar;
   
   //--- Update indicator buffers
   if(!UpdateIndicators())
      return;
   
   //--- Check trading hours
   if(UseTradingHours && !IsTradingTime())
      return;
   
   //--- Manage existing positions
   ManagePositions();
   
   //--- Check for entry signals
   if(CountPositions() == 0)
   {
      CheckEntrySignals();
   }
}

//+------------------------------------------------------------------+
//| Update indicator values                                          |
//+------------------------------------------------------------------+
bool UpdateIndicators()
{
   if(CopyBuffer(handleFastMA, 0, 0, 3, fastMA) < 3)
   {
      Print("Failed to copy Fast MA data");
      return false;
   }
   
   if(CopyBuffer(handleSlowMA, 0, 0, 3, slowMA) < 3)
   {
      Print("Failed to copy Slow MA data");
      return false;
   }
   
   return true;
}

//+------------------------------------------------------------------+
//| Check if current time is within trading hours                    |
//+------------------------------------------------------------------+
bool IsTradingTime()
{
   MqlDateTime tm;
   TimeToStruct(TimeCurrent(), tm);
   
   int currentHour = tm.hour;
   
   if(StartHour <= EndHour)
   {
      return (currentHour >= StartHour && currentHour < EndHour);
   }
   else
   {
      return (currentHour >= StartHour || currentHour < EndHour);
   }
}

//+------------------------------------------------------------------+
//| Check for entry signals                                          |
//+------------------------------------------------------------------+
void CheckEntrySignals()
{
   //--- Get current price
   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   
   //--- Check for buy signal (Fast MA crosses above Slow MA)
   if(fastMA[1] > slowMA[1] && fastMA[2] <= slowMA[2])
   {
      if(fastMA[0] > slowMA[0]) // Confirm trend
      {
         OpenBuyPosition(ask);
      }
   }
   
   //--- Check for sell signal (Fast MA crosses below Slow MA)
   if(fastMA[1] < slowMA[1] && fastMA[2] >= slowMA[2])
   {
      if(fastMA[0] < slowMA[0]) // Confirm trend
      {
         OpenSellPosition(bid);
      }
   }
}

//+------------------------------------------------------------------+
//| Open Buy Position                                                |
//+------------------------------------------------------------------+
void OpenBuyPosition(double price)
{
   double sl = CalculateStopLoss(ORDER_TYPE_BUY, price);
   double tp = CalculateTakeProfit(ORDER_TYPE_BUY, price);
   double lots = CalculateLotSize(price, sl);
   
   //--- Normalize values
   sl = NormalizeDouble(sl, digits);
   tp = NormalizeDouble(tp, digits);
   lots = NormalizeLot(lots);
   
   //--- Validate lot size
   if(lots < minLot || lots > maxLot)
   {
      Print("Invalid lot size: ", lots);
      return;
   }
   
   //--- Send order
   if(trade.Buy(lots, _Symbol, price, sl, tp, TradeComment))
   {
      Print("Buy order opened successfully. Ticket: ", trade.ResultOrder());
      Print("Price: ", price, " SL: ", sl, " TP: ", tp, " Lots: ", lots);
   }
   else
   {
      Print("Failed to open buy order. Error: ", GetLastError());
   }
}

//+------------------------------------------------------------------+
//| Open Sell Position                                               |
//+------------------------------------------------------------------+
void OpenSellPosition(double price)
{
   double sl = CalculateStopLoss(ORDER_TYPE_SELL, price);
   double tp = CalculateTakeProfit(ORDER_TYPE_SELL, price);
   double lots = CalculateLotSize(price, sl);
   
   //--- Normalize values
   sl = NormalizeDouble(sl, digits);
   tp = NormalizeDouble(tp, digits);
   lots = NormalizeLot(lots);
   
   //--- Validate lot size
   if(lots < minLot || lots > maxLot)
   {
      Print("Invalid lot size: ", lots);
      return;
   }
   
   //--- Send order
   if(trade.Sell(lots, _Symbol, price, sl, tp, TradeComment))
   {
      Print("Sell order opened successfully. Ticket: ", trade.ResultOrder());
      Print("Price: ", price, " SL: ", sl, " TP: ", tp, " Lots: ", lots);
   }
   else
   {
      Print("Failed to open sell order. Error: ", GetLastError());
   }
}

//+------------------------------------------------------------------+
//| Calculate Stop Loss                                              |
//+------------------------------------------------------------------+
double CalculateStopLoss(ENUM_ORDER_TYPE orderType, double price)
{
   double sl = 0;
   double slDistance = StopLossPips * point * 10; // Convert pips to price
   
   if(orderType == ORDER_TYPE_BUY)
   {
      sl = price - slDistance;
   }
   else if(orderType == ORDER_TYPE_SELL)
   {
      sl = price + slDistance;
   }
   
   return sl;
}

//+------------------------------------------------------------------+
//| Calculate Take Profit                                            |
//+------------------------------------------------------------------+
double CalculateTakeProfit(ENUM_ORDER_TYPE orderType, double price)
{
   double tp = 0;
   double tpDistance = TakeProfitPips * point * 10; // Convert pips to price
   
   if(orderType == ORDER_TYPE_BUY)
   {
      tp = price + tpDistance;
   }
   else if(orderType == ORDER_TYPE_SELL)
   {
      tp = price - tpDistance;
   }
   
   return tp;
}

//+------------------------------------------------------------------+
//| Calculate Lot Size based on risk                                 |
//+------------------------------------------------------------------+
double CalculateLotSize(double entryPrice, double stopLoss)
{
   if(UseFixedLot)
      return FixedLotSize;
   
   double accountBalance = AccountInfoDouble(ACCOUNT_BALANCE);
   double riskAmount = accountBalance * (RiskPercent / 100.0);
   
   double slDistance = MathAbs(entryPrice - stopLoss);
   
   if(slDistance == 0)
      return MinLotSize;
   
   double ticksDistance = slDistance / tickSize;
   double riskPerLot = ticksDistance * tickValue;
   
   if(riskPerLot == 0)
      return MinLotSize;
   
   double lots = riskAmount / riskPerLot;
   
   //--- Apply limits
   if(lots > MaxLotSize)
      lots = MaxLotSize;
   if(lots < MinLotSize)
      lots = MinLotSize;
   
   return lots;
}

//+------------------------------------------------------------------+
//| Normalize lot size                                               |
//+------------------------------------------------------------------+
double NormalizeLot(double lots)
{
   lots = MathFloor(lots / lotStep) * lotStep;
   
   if(lots < minLot)
      lots = minLot;
   if(lots > maxLot)
      lots = maxLot;
   
   return NormalizeDouble(lots, 2);
}

//+------------------------------------------------------------------+
//| Count positions                                                   |
//+------------------------------------------------------------------+
int CountPositions()
{
   int count = 0;
   
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      ulong ticket = PositionGetTicket(i);
      if(ticket <= 0)
         continue;
         
      if(PositionGetString(POSITION_SYMBOL) == _Symbol &&
         PositionGetInteger(POSITION_MAGIC) == MagicNumber)
      {
         count++;
      }
   }
   
   return count;
}

//+------------------------------------------------------------------+
//| Manage existing positions (Trailing Stop)                        |
//+------------------------------------------------------------------+
void ManagePositions()
{
   if(!UseTrailingStop)
      return;
   
   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      ulong ticket = PositionGetTicket(i);
      if(ticket <= 0)
         continue;
         
      if(PositionGetString(POSITION_SYMBOL) != _Symbol ||
         PositionGetInteger(POSITION_MAGIC) != MagicNumber)
         continue;
      
      double positionOpenPrice = PositionGetDouble(POSITION_PRICE_OPEN);
      double currentSL = PositionGetDouble(POSITION_SL);
      double currentTP = PositionGetDouble(POSITION_TP);
      ENUM_POSITION_TYPE posType = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
      
      double newSL = currentSL;
      double trailDistance = TrailingStopPips * point * 10;
      double trailStep = TrailingStepPips * point * 10;
      
      if(posType == POSITION_TYPE_BUY)
      {
         double trailPrice = bid - trailDistance;
         
         if(trailPrice > currentSL + trailStep || currentSL == 0)
         {
            newSL = NormalizeDouble(trailPrice, digits);
            
            if(newSL != currentSL && newSL > positionOpenPrice)
            {
               if(trade.PositionModify(ticket, newSL, currentTP))
               {
                  Print("Trailing stop updated for Buy position. Ticket: ", ticket, " New SL: ", newSL);
               }
            }
         }
      }
      else if(posType == POSITION_TYPE_SELL)
      {
         double trailPrice = ask + trailDistance;
         
         if(trailPrice < currentSL - trailStep || currentSL == 0)
         {
            newSL = NormalizeDouble(trailPrice, digits);
            
            if(newSL != currentSL && newSL < positionOpenPrice)
            {
               if(trade.PositionModify(ticket, newSL, currentTP))
               {
                  Print("Trailing stop updated for Sell position. Ticket: ", ticket, " New SL: ", newSL);
               }
            }
         }
      }
   }
}
//+------------------------------------------------------------------+
