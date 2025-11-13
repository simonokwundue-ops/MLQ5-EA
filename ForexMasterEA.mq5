//+------------------------------------------------------------------+
//|                                                 ForexMasterEA.mq5 |
//|                        Professional Forex Trading Expert Advisor  |
//|                   Based on Forex Educational Materials Analysis   |
//+------------------------------------------------------------------+
#property copyright "MLQ5-EA Project"
#property link      "https://github.com/simonokwundue-ops/MLQ5-EA"
#property version   "1.00"
#property description "A disciplined Expert Advisor implementing professional trading strategies"
#property description "Includes Moving Average crossover, ADX trend strength, and professional risk management"

//--- Input Parameters
input group "=== Moving Average Strategy ==="
input int      FastMA_Period = 10;           // Fast Moving Average Period
input int      SlowMA_Period = 30;           // Slow Moving Average Period
input ENUM_MA_METHOD MA_Method = MODE_EMA;   // Moving Average Method
input ENUM_APPLIED_PRICE MA_AppliedPrice = PRICE_CLOSE; // Applied Price

input group "=== Trend Strength Confirmation ==="
input bool     UseADX = true;                // Use ADX Filter
input int      ADX_Period = 14;              // ADX Period
input double   ADX_MinLevel = 20.0;          // Minimum ADX Level for Trade

input group "=== Risk Management ==="
input double   RiskPercent = 2.0;            // Risk Per Trade (% of Balance)
input double   StopLossPips = 50.0;          // Stop Loss in Pips
input double   TakeProfitPips = 100.0;       // Take Profit in Pips
input double   MaxSpreadPips = 3.0;          // Maximum Spread in Pips

input group "=== Money Management ==="
input double   MinLotSize = 0.01;            // Minimum Lot Size
input double   MaxLotSize = 10.0;            // Maximum Lot Size
input bool     UseFixedLot = false;          // Use Fixed Lot Size
input double   FixedLotSize = 0.1;           // Fixed Lot Size (if enabled)

input group "=== Trading Hours ==="
input bool     UseTradingHours = false;      // Enable Trading Hours Filter
input int      StartHour = 8;                // Start Trading Hour (Server Time)
input int      EndHour = 20;                 // End Trading Hour (Server Time)

input group "=== Expert Advisor Settings ==="
input int      MagicNumber = 123456;         // Magic Number
input string   TradeComment = "ForexMasterEA"; // Trade Comment

//--- Global Variables
int handleFastMA;
int handleSlowMA;
int handleADX;
double fastMA[], slowMA[];
double adxMain[], adxPlus[], adxMinus[];
datetime lastBarTime;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
   //--- Validate input parameters
   if(FastMA_Period >= SlowMA_Period)
   {
      Print("ERROR: Fast MA Period must be less than Slow MA Period!");
      return(INIT_PARAMETERS_INCORRECT);
   }
   
   if(RiskPercent <= 0 || RiskPercent > 10)
   {
      Print("ERROR: Risk Percent must be between 0 and 10!");
      return(INIT_PARAMETERS_INCORRECT);
   }
   
   if(StopLossPips <= 0 || TakeProfitPips <= 0)
   {
      Print("ERROR: Stop Loss and Take Profit must be greater than 0!");
      return(INIT_PARAMETERS_INCORRECT);
   }
   
   //--- Initialize indicators
   handleFastMA = iMA(_Symbol, PERIOD_CURRENT, FastMA_Period, 0, MA_Method, MA_AppliedPrice);
   handleSlowMA = iMA(_Symbol, PERIOD_CURRENT, SlowMA_Period, 0, MA_Method, MA_AppliedPrice);
   
   if(UseADX)
   {
      handleADX = iADX(_Symbol, PERIOD_CURRENT, ADX_Period);
   }
   
   //--- Check if handles are valid
   if(handleFastMA == INVALID_HANDLE || handleSlowMA == INVALID_HANDLE)
   {
      Print("ERROR: Failed to create Moving Average indicators!");
      return(INIT_FAILED);
   }
   
   if(UseADX && handleADX == INVALID_HANDLE)
   {
      Print("ERROR: Failed to create ADX indicator!");
      return(INIT_FAILED);
   }
   
   //--- Set array as series
   ArraySetAsSeries(fastMA, true);
   ArraySetAsSeries(slowMA, true);
   ArraySetAsSeries(adxMain, true);
   ArraySetAsSeries(adxPlus, true);
   ArraySetAsSeries(adxMinus, true);
   
   //--- Initialize last bar time
   lastBarTime = 0;
   
   Print("ForexMasterEA initialized successfully on ", _Symbol);
   Print("Fast MA: ", FastMA_Period, " | Slow MA: ", SlowMA_Period);
   Print("Risk per trade: ", RiskPercent, "% | SL: ", StopLossPips, " pips | TP: ", TakeProfitPips, " pips");
   
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
   if(handleADX != INVALID_HANDLE)
      IndicatorRelease(handleADX);
      
   Print("ForexMasterEA deinitialized. Reason: ", reason);
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
   //--- Check if we have a new bar
   if(!IsNewBar())
      return;
   
   //--- Update indicator values
   if(!UpdateIndicators())
      return;
   
   //--- Check trading conditions
   if(!CheckTradingConditions())
      return;
   
   //--- Get current signal
   int signal = GetTradingSignal();
   
   //--- Execute trades based on signal
   if(signal == 1)  // Buy signal
   {
      if(PositionsTotal() == 0 || !HasOpenPosition())
      {
         OpenBuyTrade();
      }
   }
   else if(signal == -1)  // Sell signal
   {
      if(PositionsTotal() == 0 || !HasOpenPosition())
      {
         OpenSellTrade();
      }
   }
   
   //--- Manage existing positions
   ManageOpenPositions();
}

//+------------------------------------------------------------------+
//| Check if new bar has formed                                      |
//+------------------------------------------------------------------+
bool IsNewBar()
{
   datetime currentBarTime = iTime(_Symbol, PERIOD_CURRENT, 0);
   
   if(lastBarTime != currentBarTime)
   {
      lastBarTime = currentBarTime;
      return true;
   }
   
   return false;
}

//+------------------------------------------------------------------+
//| Update indicator values                                          |
//+------------------------------------------------------------------+
bool UpdateIndicators()
{
   //--- Copy Moving Average values
   if(CopyBuffer(handleFastMA, 0, 0, 3, fastMA) < 3)
   {
      Print("ERROR: Failed to copy Fast MA data!");
      return false;
   }
   
   if(CopyBuffer(handleSlowMA, 0, 0, 3, slowMA) < 3)
   {
      Print("ERROR: Failed to copy Slow MA data!");
      return false;
   }
   
   //--- Copy ADX values if enabled
   if(UseADX)
   {
      if(CopyBuffer(handleADX, 0, 0, 3, adxMain) < 3)
      {
         Print("ERROR: Failed to copy ADX Main data!");
         return false;
      }
      
      if(CopyBuffer(handleADX, 1, 0, 3, adxPlus) < 3)
      {
         Print("ERROR: Failed to copy ADX +DI data!");
         return false;
      }
      
      if(CopyBuffer(handleADX, 2, 0, 3, adxMinus) < 3)
      {
         Print("ERROR: Failed to copy ADX -DI data!");
         return false;
      }
   }
   
   return true;
}

//+------------------------------------------------------------------+
//| Helper: Convert pips to points for current symbol                |
//+------------------------------------------------------------------+
double PipToPoint()
{
   int digits = (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS);
   if(digits == 3 || digits == 5)
      return 10.0;
   else
      return 1.0;
}

//+------------------------------------------------------------------+
//| Check general trading conditions                                 |
//+------------------------------------------------------------------+
bool CheckTradingConditions()
{
   //--- Check spread
   double spread = (double)(SymbolInfoInteger(_Symbol, SYMBOL_SPREAD));
   if(spread > MaxSpreadPips * PipToPoint())  // Convert pips to points
   {
      return false;
   }
   
   //--- Check trading hours
   if(UseTradingHours)
   {
      MqlDateTime time;
      TimeToStruct(TimeCurrent(), time);
      
      if(time.hour < StartHour || time.hour >= EndHour)
      {
         return false;
      }
   }
   
   //--- Check if trading is allowed
   if(!TerminalInfoInteger(TERMINAL_TRADE_ALLOWED))
   {
      return false;
   }
   
   if(!MQLInfoInteger(MQL_TRADE_ALLOWED))
   {
      return false;
   }
   
   return true;
}

//+------------------------------------------------------------------+
//| Get trading signal based on strategy                             |
//+------------------------------------------------------------------+
int GetTradingSignal()
{
   //--- Moving Average Crossover Strategy
   bool bullishCross = (fastMA[1] > slowMA[1]) && (fastMA[2] <= slowMA[2]);
   bool bearishCross = (fastMA[1] < slowMA[1]) && (fastMA[2] >= slowMA[2]);
   
   //--- Additional confirmation: Fast MA must be clearly above/below Slow MA
   bool bullishTrend = fastMA[0] > slowMA[0];
   bool bearishTrend = fastMA[0] < slowMA[0];
   
   //--- ADX Filter (if enabled)
   bool adxConfirm = true;
   if(UseADX)
   {
      // ADX must be above minimum level for strong trend
      if(adxMain[0] < ADX_MinLevel)
      {
         adxConfirm = false;
      }
   }
   
   //--- Generate signals
   if(bullishCross && bullishTrend && adxConfirm)
   {
      return 1;  // Buy signal
   }
   else if(bearishCross && bearishTrend && adxConfirm)
   {
      return -1;  // Sell signal
   }
   
   return 0;  // No signal
}

//+------------------------------------------------------------------+
//| Check if there's an open position for this EA                    |
//+------------------------------------------------------------------+
bool HasOpenPosition()
{
   for(int i = 0; i < PositionsTotal(); i++)
   {
      ulong ticket = PositionGetTicket(i);
      if(ticket > 0)
      {
         if(PositionGetString(POSITION_SYMBOL) == _Symbol &&
            PositionGetInteger(POSITION_MAGIC) == MagicNumber)
         {
            return true;
         }
      }
   }
   return false;
}

//+------------------------------------------------------------------+
//| Calculate lot size based on risk management                      |
//+------------------------------------------------------------------+
double CalculateLotSize()
{
   if(UseFixedLot)
   {
      return NormalizeLot(FixedLotSize);
   }
   
   //--- Get account balance
   double balance = AccountInfoDouble(ACCOUNT_BALANCE);
   
   //--- Calculate risk amount
   double riskAmount = balance * (RiskPercent / 100.0);
   
   //--- Get pip value
   double tickSize = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
   double tickValue = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
   double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
   
   //--- Calculate lot size
   double pipValue = tickValue;
   if(tickSize > 0 && point > 0)
   {
      pipValue = (tickValue / tickSize) * point * 10;  // Value of 1 pip for 1 lot
   }
   
   double lotSize = 0.01;
   if(pipValue > 0 && StopLossPips > 0)
   {
      lotSize = riskAmount / (StopLossPips * pipValue);
   }
   
   //--- Normalize and limit lot size
   return NormalizeLot(lotSize);
}

//+------------------------------------------------------------------+
//| Normalize lot size according to symbol specifications            |
//+------------------------------------------------------------------+
double NormalizeLot(double lot)
{
   double minLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   double maxLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
   double lotStep = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
   
   //--- Apply user limits
   if(MinLotSize > minLot)
      minLot = MinLotSize;
   if(MaxLotSize < maxLot)
      maxLot = MaxLotSize;
   
   //--- Normalize to lot step
   lot = MathFloor(lot / lotStep) * lotStep;
   
   //--- Apply limits
   if(lot < minLot)
      lot = minLot;
   if(lot > maxLot)
      lot = maxLot;
   
   return lot;
}

//+------------------------------------------------------------------+
//| Open Buy Trade                                                   |
//+------------------------------------------------------------------+
void OpenBuyTrade()
{
   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
   int digits = (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS);
   
   //--- Calculate SL and TP
   double sl = NormalizeDouble(ask - StopLossPips * 10 * point, digits);
   double tp = NormalizeDouble(ask + TakeProfitPips * 10 * point, digits);
   
   //--- Calculate lot size
   double lot = CalculateLotSize();
   
   //--- Prepare trade request
   MqlTradeRequest request = {};
   MqlTradeResult result = {};
   
   request.action = TRADE_ACTION_DEAL;
   request.symbol = _Symbol;
   request.volume = lot;
   request.type = ORDER_TYPE_BUY;
   request.price = ask;
   request.sl = sl;
   request.tp = tp;
   request.deviation = 10;
   request.magic = MagicNumber;
   request.comment = TradeComment;
   request.type_filling = ORDER_FILLING_FOK;
   
   //--- Send order
   if(!OrderSend(request, result))
   {
      Print("BUY order failed! Error: ", GetLastError());
      Print("Result Code: ", result.retcode, " | ", result.comment);
   }
   else
   {
      if(result.retcode == TRADE_RETCODE_DONE || result.retcode == TRADE_RETCODE_PLACED)
      {
         Print("BUY order opened successfully! Ticket: ", result.order, " | Volume: ", lot, " | Price: ", ask);
      }
      else
      {
         Print("BUY order unsuccessful. Code: ", result.retcode, " | ", result.comment);
      }
   }
}

//+------------------------------------------------------------------+
//| Open Sell Trade                                                  |
//+------------------------------------------------------------------+
void OpenSellTrade()
{
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
   int digits = (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS);
   double pip = point * ((digits == 3 || digits == 5) ? 10 : 1);
   
   //--- Calculate SL and TP
   double sl = NormalizeDouble(bid + StopLossPips * pip, digits);
   double tp = NormalizeDouble(bid - TakeProfitPips * pip, digits);
   
   //--- Calculate lot size
   double lot = CalculateLotSize();
   
   //--- Prepare trade request
   MqlTradeRequest request = {};
   MqlTradeResult result = {};
   
   request.action = TRADE_ACTION_DEAL;
   request.symbol = _Symbol;
   request.volume = lot;
   request.type = ORDER_TYPE_SELL;
   request.price = bid;
   request.sl = sl;
   request.tp = tp;
   request.deviation = 10;
   request.magic = MagicNumber;
   request.comment = TradeComment;
   request.type_filling = ORDER_FILLING_FOK;
   
   //--- Send order
   if(!OrderSend(request, result))
   {
      Print("SELL order failed! Error: ", GetLastError());
      Print("Result Code: ", result.retcode, " | ", result.comment);
   }
   else
   {
      if(result.retcode == TRADE_RETCODE_DONE || result.retcode == TRADE_RETCODE_PLACED)
      {
         Print("SELL order opened successfully! Ticket: ", result.order, " | Volume: ", lot, " | Price: ", bid);
      }
      else
      {
         Print("SELL order unsuccessful. Code: ", result.retcode, " | ", result.comment);
      }
   }
}

//+------------------------------------------------------------------+
//| Manage open positions (trailing stop, etc.)                      |
//+------------------------------------------------------------------+
void ManageOpenPositions()
{
   //--- This function can be extended to include:
   //--- - Trailing stop loss
   //--- - Partial profit taking
   //--- - Breakeven stop loss
   //--- - Time-based exits
   
   // For now, positions are managed by the predefined SL and TP
   // Future enhancements can add more sophisticated position management
}
//+------------------------------------------------------------------+
