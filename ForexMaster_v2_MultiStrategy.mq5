//+------------------------------------------------------------------+
//|                                   ForexMaster_v2_MultiStrategy.mq5 |
//|                          Productivity-Focused Multi-Strategy EA    |
//|                              Enhanced Risk Management System       |
//+------------------------------------------------------------------+
#property copyright "MLQ5-EA Project v2.0"
#property link      "https://github.com/simonokwundue-ops/MLQ5-EA"
#property version   "2.00"
#property description "Advanced multi-strategy EA with portfolio management"
#property description "Targets 5-20 positions daily with 60-70% win rate"

#include <Trade\Trade.mqh>
#include <Trade\PositionInfo.mqh>
#include <Trade\AccountInfo.mqh>

//--- Global Objects
CTrade trade;
CPositionInfo positionInfo;
CAccountInfo accountInfo;

//--- Input Parameters
input group "=== Multi-Strategy Settings ==="
input bool     UseMAStrategy = true;           // Use MA Crossover Strategy
input bool     UseRSIStrategy = true;          // Use RSI Strategy
input bool     UseBBStrategy = true;           // Use Bollinger Bands Strategy
input bool     UseMACDStrategy = true;         // Use MACD Strategy
input int      MinSignalScore = 60;            // Minimum Signal Quality Score (0-100)

input group "=== Multi-Timeframe Analysis ==="
input bool     UseMultiTimeframe = true;       // Enable Multi-Timeframe Analysis
input ENUM_TIMEFRAMES TimeFrame1 = PERIOD_M15; // Timeframe 1 (Fast)
input ENUM_TIMEFRAMES TimeFrame2 = PERIOD_M30; // Timeframe 2 (Medium)
input ENUM_TIMEFRAMES TimeFrame3 = PERIOD_H1;  // Timeframe 3 (Slow)
input int      MinTFConfirmation = 2;          // Min Timeframes for Confirmation (1-3)

input group "=== Moving Average Settings ==="
input int      FastMA_Period = 10;             // Fast MA Period
input int      SlowMA_Period = 30;             // Slow MA Period
input ENUM_MA_METHOD MA_Method = MODE_EMA;     // MA Method

input group "=== RSI Settings ==="
input int      RSI_Period = 14;                // RSI Period
input double   RSI_Oversold = 30.0;            // RSI Oversold Level
input double   RSI_Overbought = 70.0;          // RSI Overbought Level

input group "=== Bollinger Bands Settings ==="
input int      BB_Period = 20;                 // BB Period
input double   BB_Deviation = 2.0;             // BB Standard Deviation
input ENUM_APPLIED_PRICE BB_AppliedPrice = PRICE_CLOSE; // BB Applied Price

input group "=== MACD Settings ==="
input int      MACD_FastEMA = 12;              // MACD Fast EMA
input int      MACD_SlowEMA = 26;              // MACD Slow EMA
input int      MACD_Signal = 9;                // MACD Signal Period

input group "=== Portfolio Management ==="
input int      MaxDailyTrades = 20;            // Maximum Trades Per Day
input int      MinDailyTrades = 5;             // Minimum Target Trades Per Day
input int      MaxConcurrentPositions = 5;     // Max Concurrent Positions
input double   MaxPortfolioRisk = 10.0;        // Max Portfolio Risk (% of Balance)

input group "=== Risk Management ==="
input double   BaseRiskPercent = 1.5;          // Base Risk Per Trade (%)
input bool     UseDynamicRisk = true;          // Use Dynamic Risk Based on Win Rate
input double   MinRiskPercent = 0.5;           // Minimum Risk Per Trade (%)
input double   MaxRiskPercent = 3.0;           // Maximum Risk Per Trade (%)
input double   StopLossPips = 40.0;            // Stop Loss (Pips)
input double   TakeProfitPips = 80.0;          // Take Profit (Pips)

input group "=== Volatility-Based Sizing ==="
input bool     UseATRSizing = true;            // Use ATR for Position Sizing
input int      ATR_Period = 14;                // ATR Period
input double   ATR_Multiplier = 2.0;           // ATR Multiplier for SL

input group "=== Advanced Position Management ==="
input bool     UseBreakeven = true;            // Auto Move to Breakeven
input double   BreakevenTriggerPips = 25.0;    // Breakeven Trigger (Pips)
input double   BreakevenOffsetPips = 5.0;      // Breakeven Offset (Pips)
input bool     UsePartialTP = true;            // Use Partial Take Profit
input double   PartialTP_Pips = 40.0;          // First Partial TP (Pips)
input double   PartialTP_Percent = 50.0;       // Partial Close % (of position)
input bool     UseTrailingStop = true;         // Use Trailing Stop
input double   TrailingStopPips = 30.0;        // Trailing Stop Distance (Pips)
input double   TrailingStepPips = 10.0;        // Trailing Step (Pips)

input group "=== Time-Based Filters ==="
input bool     UseTimeFilter = true;           // Enable Time-of-Day Filter
input int      LondonOpenHour = 7;             // London Session Start
input int      NewYorkOpenHour = 12;           // New York Session Start
input int      AsianCloseHour = 8;             // Asian Session Close
input bool     TradeAsianSession = false;      // Trade During Asian Session
input bool     AvoidNewsEvents = true;         // Avoid Major News Times

input group "=== Money Management ==="
input double   MinLotSize = 0.01;              // Minimum Lot Size
input double   MaxLotSize = 5.0;               // Maximum Lot Size
input bool     UseCompounding = true;          // Use Compounding

input group "=== Expert Advisor Settings ==="
input int      MagicNumber = 234567;           // Magic Number
input string   TradeComment = "ForexMasterV2"; // Trade Comment
input int      Slippage = 10;                  // Slippage (Points)

//--- Global Variables
int handleFastMA_TF1, handleSlowMA_TF1;
int handleFastMA_TF2, handleSlowMA_TF2;
int handleFastMA_TF3, handleSlowMA_TF3;
int handleRSI_TF1, handleRSI_TF2, handleRSI_TF3;
int handleBB_TF1, handleBB_TF2, handleBB_TF3;
int handleMACD_TF1, handleMACD_TF2, handleMACD_TF3;
int handleATR;

double fastMA_TF1[], slowMA_TF1[], fastMA_TF2[], slowMA_TF2[], fastMA_TF3[], slowMA_TF3[];
double rsi_TF1[], rsi_TF2[], rsi_TF3[];
double bb_upper_TF1[], bb_middle_TF1[], bb_lower_TF1[];
double bb_upper_TF2[], bb_middle_TF2[], bb_lower_TF2[];
double bb_upper_TF3[], bb_middle_TF3[], bb_lower_TF3[];
double macd_main_TF1[], macd_signal_TF1[];
double macd_main_TF2[], macd_signal_TF2[];
double macd_main_TF3[], macd_signal_TF3[];
double atr[];

datetime lastBarTime;
datetime lastTradeTime;
int dailyTradeCount = 0;
datetime currentDay = 0;
double dailyProfitLoss = 0.0;
double totalWins = 0;
double totalTrades = 0;
double currentWinRate = 0.5; // Start at 50%

struct PositionTracker {
   ulong ticket;
   bool breakEvenSet;
   bool partialTPTaken;
   datetime openTime;
   double openPrice;
   double initialLots;
   int signalScore;
};

PositionTracker openPositions[100];
int positionCount = 0;

//+------------------------------------------------------------------+
//| Expert initialization function                                     |
//+------------------------------------------------------------------+
int OnInit()
{
   //--- Setup trade object
   trade.SetExpertMagicNumber(MagicNumber);
   trade.SetDeviationInPoints(Slippage);
   trade.SetTypeFilling(ORDER_FILLING_FOK);
   trade.SetAsyncMode(false);
   
   //--- Validate parameters
   if(!ValidateParameters())
      return INIT_PARAMETERS_INCORRECT;
   
   //--- Initialize indicators
   if(!InitializeIndicators())
      return INIT_FAILED;
   
   //--- Set arrays as series
   SetArraysAsSeries();
   
   //--- Initialize variables
   lastBarTime = 0;
   lastTradeTime = 0;
   currentDay = 0;
   dailyTradeCount = 0;
   
   //--- Load historical win rate if available
   LoadWinRateHistory();
   
   Print("=== ForexMaster v2.0 Multi-Strategy EA Initialized ===");
   Print("Strategies Active: MA=", UseMAStrategy, " RSI=", UseRSIStrategy, 
         " BB=", UseBBStrategy, " MACD=", UseMACDStrategy);
   Print("Multi-Timeframe: ", UseMultiTimeframe, " | Min TF Confirmation: ", MinTFConfirmation);
   Print("Daily Trade Target: ", MinDailyTrades, "-", MaxDailyTrades);
   Print("Max Concurrent Positions: ", MaxConcurrentPositions);
   Print("Base Risk: ", BaseRiskPercent, "% | Dynamic Risk: ", UseDynamicRisk);
   Print("Advanced Features: Breakeven=", UseBreakeven, " PartialTP=", UsePartialTP, " Trailing=", UseTrailingStop);
   
   return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                   |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   //--- Save win rate history
   SaveWinRateHistory();
   
   //--- Release all indicator handles
   ReleaseIndicators();
   
   Print("ForexMaster v2.0 deinitialized. Reason: ", reason);
   Print("Final Win Rate: ", DoubleToString(currentWinRate * 100, 2), "%");
   Print("Total Trades Today: ", dailyTradeCount);
}

//+------------------------------------------------------------------+
//| Expert tick function                                               |
//+------------------------------------------------------------------+
void OnTick()
{
   //--- Check for new bar
   if(!IsNewBar())
      return;
   
   //--- Reset daily counter
   CheckAndResetDailyCounter();
   
   //--- Update all indicators
   if(!UpdateAllIndicators())
      return;
   
   //--- Manage existing positions
   ManageAllPositions();
   
   //--- Check trading conditions
   if(!CanTrade())
      return;
   
   //--- Analyze and execute trades
   AnalyzeAndTrade();
}

//+------------------------------------------------------------------+
//| Check if new bar has formed                                        |
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
//| Check and reset daily counter                                     |
//+------------------------------------------------------------------+
void CheckAndResetDailyCounter()
{
   MqlDateTime dt;
   TimeToStruct(TimeCurrent(), dt);
   
   datetime today = StringToTime(IntegerToString(dt.year) + "." + 
                                  IntegerToString(dt.mon) + "." + 
                                  IntegerToString(dt.day));
   
   if(currentDay != today)
   {
      if(currentDay != 0)
      {
         Print("=== Daily Summary ===");
         Print("Date: ", TimeToString(currentDay, TIME_DATE));
         Print("Total Trades: ", dailyTradeCount);
         Print("Daily P/L: ", DoubleToString(dailyProfitLoss, 2));
         Print("Win Rate: ", DoubleToString(currentWinRate * 100, 2), "%");
      }
      
      currentDay = today;
      dailyTradeCount = 0;
      dailyProfitLoss = 0.0;
   }
}

//+------------------------------------------------------------------+
//| Validate input parameters                                          |
//+------------------------------------------------------------------+
bool ValidateParameters()
{
   if(FastMA_Period >= SlowMA_Period)
   {
      Print("ERROR: Fast MA must be less than Slow MA");
      return false;
   }
   
   if(MinSignalScore < 0 || MinSignalScore > 100)
   {
      Print("ERROR: Signal Score must be between 0-100");
      return false;
   }
   
   if(MaxDailyTrades < MinDailyTrades)
   {
      Print("ERROR: Max daily trades must be >= Min daily trades");
      return false;
   }
   
   if(BaseRiskPercent < MinRiskPercent || BaseRiskPercent > MaxRiskPercent)
   {
      Print("ERROR: Base risk must be between Min and Max risk");
      return false;
   }
   
   return true;
}

//+------------------------------------------------------------------+
//| Initialize all indicators                                          |
//+------------------------------------------------------------------+
bool InitializeIndicators()
{
   //--- Initialize MA indicators
   if(UseMAStrategy)
   {
      handleFastMA_TF1 = iMA(_Symbol, TimeFrame1, FastMA_Period, 0, MA_Method, PRICE_CLOSE);
      handleSlowMA_TF1 = iMA(_Symbol, TimeFrame1, SlowMA_Period, 0, MA_Method, PRICE_CLOSE);
      
      if(UseMultiTimeframe)
      {
         handleFastMA_TF2 = iMA(_Symbol, TimeFrame2, FastMA_Period, 0, MA_Method, PRICE_CLOSE);
         handleSlowMA_TF2 = iMA(_Symbol, TimeFrame2, SlowMA_Period, 0, MA_Method, PRICE_CLOSE);
         handleFastMA_TF3 = iMA(_Symbol, TimeFrame3, FastMA_Period, 0, MA_Method, PRICE_CLOSE);
         handleSlowMA_TF3 = iMA(_Symbol, TimeFrame3, SlowMA_Period, 0, MA_Method, PRICE_CLOSE);
      }
      
      if(handleFastMA_TF1 == INVALID_HANDLE || handleSlowMA_TF1 == INVALID_HANDLE)
      {
         Print("ERROR: Failed to create MA indicators");
         return false;
      }
   }
   
   //--- Initialize RSI indicators
   if(UseRSIStrategy)
   {
      handleRSI_TF1 = iRSI(_Symbol, TimeFrame1, RSI_Period, PRICE_CLOSE);
      
      if(UseMultiTimeframe)
      {
         handleRSI_TF2 = iRSI(_Symbol, TimeFrame2, RSI_Period, PRICE_CLOSE);
         handleRSI_TF3 = iRSI(_Symbol, TimeFrame3, RSI_Period, PRICE_CLOSE);
      }
      
      if(handleRSI_TF1 == INVALID_HANDLE)
      {
         Print("ERROR: Failed to create RSI indicator");
         return false;
      }
   }
   
   //--- Initialize Bollinger Bands indicators
   if(UseBBStrategy)
   {
      handleBB_TF1 = iBands(_Symbol, TimeFrame1, BB_Period, 0, BB_Deviation, BB_AppliedPrice);
      
      if(UseMultiTimeframe)
      {
         handleBB_TF2 = iBands(_Symbol, TimeFrame2, BB_Period, 0, BB_Deviation, BB_AppliedPrice);
         handleBB_TF3 = iBands(_Symbol, TimeFrame3, BB_Period, 0, BB_Deviation, BB_AppliedPrice);
      }
      
      if(handleBB_TF1 == INVALID_HANDLE)
      {
         Print("ERROR: Failed to create Bollinger Bands indicator");
         return false;
      }
   }
   
   //--- Initialize MACD indicators
   if(UseMACDStrategy)
   {
      handleMACD_TF1 = iMACD(_Symbol, TimeFrame1, MACD_FastEMA, MACD_SlowEMA, MACD_Signal, PRICE_CLOSE);
      
      if(UseMultiTimeframe)
      {
         handleMACD_TF2 = iMACD(_Symbol, TimeFrame2, MACD_FastEMA, MACD_SlowEMA, MACD_Signal, PRICE_CLOSE);
         handleMACD_TF3 = iMACD(_Symbol, TimeFrame3, MACD_FastEMA, MACD_SlowEMA, MACD_Signal, PRICE_CLOSE);
      }
      
      if(handleMACD_TF1 == INVALID_HANDLE)
      {
         Print("ERROR: Failed to create MACD indicator");
         return false;
      }
   }
   
   //--- Initialize ATR for volatility-based sizing
   if(UseATRSizing)
   {
      handleATR = iATR(_Symbol, PERIOD_CURRENT, ATR_Period);
      
      if(handleATR == INVALID_HANDLE)
      {
         Print("ERROR: Failed to create ATR indicator");
         return false;
      }
   }
   
   return true;
}

//+------------------------------------------------------------------+
//| Set all arrays as series                                          |
//+------------------------------------------------------------------+
void SetArraysAsSeries()
{
   ArraySetAsSeries(fastMA_TF1, true);
   ArraySetAsSeries(slowMA_TF1, true);
   ArraySetAsSeries(fastMA_TF2, true);
   ArraySetAsSeries(slowMA_TF2, true);
   ArraySetAsSeries(fastMA_TF3, true);
   ArraySetAsSeries(slowMA_TF3, true);
   
   ArraySetAsSeries(rsi_TF1, true);
   ArraySetAsSeries(rsi_TF2, true);
   ArraySetAsSeries(rsi_TF3, true);
   
   ArraySetAsSeries(bb_upper_TF1, true);
   ArraySetAsSeries(bb_middle_TF1, true);
   ArraySetAsSeries(bb_lower_TF1, true);
   ArraySetAsSeries(bb_upper_TF2, true);
   ArraySetAsSeries(bb_middle_TF2, true);
   ArraySetAsSeries(bb_lower_TF2, true);
   ArraySetAsSeries(bb_upper_TF3, true);
   ArraySetAsSeries(bb_middle_TF3, true);
   ArraySetAsSeries(bb_lower_TF3, true);
   
   ArraySetAsSeries(macd_main_TF1, true);
   ArraySetAsSeries(macd_signal_TF1, true);
   ArraySetAsSeries(macd_main_TF2, true);
   ArraySetAsSeries(macd_signal_TF2, true);
   ArraySetAsSeries(macd_main_TF3, true);
   ArraySetAsSeries(macd_signal_TF3, true);
   
   ArraySetAsSeries(atr, true);
}

//+------------------------------------------------------------------+
//| Update all indicator buffers                                       |
//+------------------------------------------------------------------+
bool UpdateAllIndicators()
{
   //--- Update MA indicators
   if(UseMAStrategy)
   {
      if(CopyBuffer(handleFastMA_TF1, 0, 0, 3, fastMA_TF1) < 3) return false;
      if(CopyBuffer(handleSlowMA_TF1, 0, 0, 3, slowMA_TF1) < 3) return false;
      
      if(UseMultiTimeframe)
      {
         if(CopyBuffer(handleFastMA_TF2, 0, 0, 3, fastMA_TF2) < 3) return false;
         if(CopyBuffer(handleSlowMA_TF2, 0, 0, 3, slowMA_TF2) < 3) return false;
         if(CopyBuffer(handleFastMA_TF3, 0, 0, 3, fastMA_TF3) < 3) return false;
         if(CopyBuffer(handleSlowMA_TF3, 0, 0, 3, slowMA_TF3) < 3) return false;
      }
   }
   
   //--- Update RSI indicators
   if(UseRSIStrategy)
   {
      if(CopyBuffer(handleRSI_TF1, 0, 0, 3, rsi_TF1) < 3) return false;
      
      if(UseMultiTimeframe)
      {
         if(CopyBuffer(handleRSI_TF2, 0, 0, 3, rsi_TF2) < 3) return false;
         if(CopyBuffer(handleRSI_TF3, 0, 0, 3, rsi_TF3) < 3) return false;
      }
   }
   
   //--- Update Bollinger Bands indicators
   if(UseBBStrategy)
   {
      if(CopyBuffer(handleBB_TF1, 0, 0, 3, bb_upper_TF1) < 3) return false;
      if(CopyBuffer(handleBB_TF1, 1, 0, 3, bb_middle_TF1) < 3) return false;
      if(CopyBuffer(handleBB_TF1, 2, 0, 3, bb_lower_TF1) < 3) return false;
      
      if(UseMultiTimeframe)
      {
         if(CopyBuffer(handleBB_TF2, 0, 0, 3, bb_upper_TF2) < 3) return false;
         if(CopyBuffer(handleBB_TF2, 1, 0, 3, bb_middle_TF2) < 3) return false;
         if(CopyBuffer(handleBB_TF2, 2, 0, 3, bb_lower_TF2) < 3) return false;
         if(CopyBuffer(handleBB_TF3, 0, 0, 3, bb_upper_TF3) < 3) return false;
         if(CopyBuffer(handleBB_TF3, 1, 0, 3, bb_middle_TF3) < 3) return false;
         if(CopyBuffer(handleBB_TF3, 2, 0, 3, bb_lower_TF3) < 3) return false;
      }
   }
   
   //--- Update MACD indicators
   if(UseMACDStrategy)
   {
      if(CopyBuffer(handleMACD_TF1, 0, 0, 3, macd_main_TF1) < 3) return false;
      if(CopyBuffer(handleMACD_TF1, 1, 0, 3, macd_signal_TF1) < 3) return false;
      
      if(UseMultiTimeframe)
      {
         if(CopyBuffer(handleMACD_TF2, 0, 0, 3, macd_main_TF2) < 3) return false;
         if(CopyBuffer(handleMACD_TF2, 1, 0, 3, macd_signal_TF2) < 3) return false;
         if(CopyBuffer(handleMACD_TF3, 0, 0, 3, macd_main_TF3) < 3) return false;
         if(CopyBuffer(handleMACD_TF3, 1, 0, 3, macd_signal_TF3) < 3) return false;
      }
   }
   
   //--- Update ATR
   if(UseATRSizing)
   {
      if(CopyBuffer(handleATR, 0, 0, 3, atr) < 3) return false;
   }
   
   return true;
}

//+------------------------------------------------------------------+
//| Check if can trade                                                 |
//+------------------------------------------------------------------+
bool CanTrade()
{
   //--- Check daily trade limit
   if(dailyTradeCount >= MaxDailyTrades)
   {
      return false;
   }
   
   //--- Check concurrent positions
   if(CountOwnPositions() >= MaxConcurrentPositions)
   {
      return false;
   }
   
   //--- Check portfolio risk
   if(GetCurrentPortfolioRisk() >= MaxPortfolioRisk)
   {
      return false;
   }
   
   //--- Check time filter
   if(UseTimeFilter && !IsGoodTradingTime())
   {
      return false;
   }
   
   //--- Check trading allowed
   if(!TerminalInfoInteger(TERMINAL_TRADE_ALLOWED) || !MQLInfoInteger(MQL_TRADE_ALLOWED))
   {
      return false;
   }
   
   return true;
}

//+------------------------------------------------------------------+
//| Check if current time is good for trading                         |
//+------------------------------------------------------------------+
bool IsGoodTradingTime()
{
   MqlDateTime dt;
   TimeToStruct(TimeCurrent(), dt);
   int currentHour = dt.hour;
   
   //--- Avoid Asian session if disabled
   if(!TradeAsianSession && currentHour >= 0 && currentHour < AsianCloseHour)
   {
      return false;
   }
   
   //--- Favor London and New York session opens (high volatility/opportunity)
   bool isLondonOpen = (currentHour >= LondonOpenHour && currentHour < LondonOpenHour + 4);
   bool isNYOpen = (currentHour >= NewYorkOpenHour && currentHour < NewYorkOpenHour + 4);
   bool isOverlap = (currentHour >= NewYorkOpenHour && currentHour < 16); // London-NY overlap
   
   if(isLondonOpen || isNYOpen || isOverlap)
   {
      return true;
   }
   
   //--- Allow trading during other hours but with higher signal requirements
   return true;
}

//+------------------------------------------------------------------+
//| Analyze market and execute trades                                 |
//+------------------------------------------------------------------+
void AnalyzeAndTrade()
{
   //--- Get trading signals from all strategies
   int signalDirection = 0; // 1=Buy, -1=Sell, 0=No signal
   int signalScore = 0;
   
   CalculateSignals(signalDirection, signalScore);
   
   //--- Check if signal meets minimum quality threshold
   if(signalScore < MinSignalScore)
   {
      return;
   }
   
   //--- Execute trade based on signal
   if(signalDirection == 1)
   {
      ExecuteBuyTrade(signalScore);
   }
   else if(signalDirection == -1)
   {
      ExecuteSellTrade(signalScore);
   }
}

//+------------------------------------------------------------------+
//| Calculate signals from all strategies                             |
//+------------------------------------------------------------------+
void CalculateSignals(int &direction, int &score)
{
   int buySignals = 0;
   int sellSignals = 0;
   int totalWeight = 0;
   
   //--- MA Strategy Signals
   if(UseMAStrategy)
   {
      int maSignal = GetMASignal();
      int maWeight = 25;
      
      if(maSignal == 1) buySignals += maWeight;
      else if(maSignal == -1) sellSignals += maWeight;
      
      totalWeight += maWeight;
   }
   
   //--- RSI Strategy Signals
   if(UseRSIStrategy)
   {
      int rsiSignal = GetRSISignal();
      int rsiWeight = 25;
      
      if(rsiSignal == 1) buySignals += rsiWeight;
      else if(rsiSignal == -1) sellSignals += rsiWeight;
      
      totalWeight += rsiWeight;
   }
   
   //--- Bollinger Bands Strategy Signals
   if(UseBBStrategy)
   {
      int bbSignal = GetBBSignal();
      int bbWeight = 25;
      
      if(bbSignal == 1) buySignals += bbWeight;
      else if(bbSignal == -1) sellSignals += bbWeight;
      
      totalWeight += bbWeight;
   }
   
   //--- MACD Strategy Signals
   if(UseMACDStrategy)
   {
      int macdSignal = GetMACDSignal();
      int macdWeight = 25;
      
      if(macdSignal == 1) buySignals += macdWeight;
      else if(macdSignal == -1) sellSignals += macdWeight;
      
      totalWeight += macdWeight;
   }
   
   //--- Calculate final signal direction and score
   if(buySignals > sellSignals)
   {
      direction = 1;
      score = (int)((double)buySignals / totalWeight * 100);
   }
   else if(sellSignals > buySignals)
   {
      direction = -1;
      score = (int)((double)sellSignals / totalWeight * 100);
   }
   else
   {
      direction = 0;
      score = 0;
   }
}

//+------------------------------------------------------------------+
//| Get MA strategy signal                                             |
//+------------------------------------------------------------------+
int GetMASignal()
{
   int tfConfirmed = 0;
   int buyVotes = 0;
   int sellVotes = 0;
   
   //--- Check TF1
   bool bullishCross_TF1 = (fastMA_TF1[1] > slowMA_TF1[1]) && (fastMA_TF1[2] <= slowMA_TF1[2]);
   bool bearishCross_TF1 = (fastMA_TF1[1] < slowMA_TF1[1]) && (fastMA_TF1[2] >= slowMA_TF1[2]);
   bool bullishTrend_TF1 = fastMA_TF1[0] > slowMA_TF1[0];
   bool bearishTrend_TF1 = fastMA_TF1[0] < slowMA_TF1[0];
   
   if((bullishCross_TF1 || bullishTrend_TF1) && fastMA_TF1[0] > slowMA_TF1[0])
   {
      buyVotes++;
      tfConfirmed++;
   }
   else if((bearishCross_TF1 || bearishTrend_TF1) && fastMA_TF1[0] < slowMA_TF1[0])
   {
      sellVotes++;
      tfConfirmed++;
   }
   
   //--- Check TF2 and TF3 if multi-timeframe enabled
   if(UseMultiTimeframe)
   {
      bool bullishTrend_TF2 = fastMA_TF2[0] > slowMA_TF2[0];
      bool bearishTrend_TF2 = fastMA_TF2[0] < slowMA_TF2[0];
      
      if(bullishTrend_TF2)
      {
         buyVotes++;
         tfConfirmed++;
      }
      else if(bearishTrend_TF2)
      {
         sellVotes++;
         tfConfirmed++;
      }
      
      bool bullishTrend_TF3 = fastMA_TF3[0] > slowMA_TF3[0];
      bool bearishTrend_TF3 = fastMA_TF3[0] < slowMA_TF3[0];
      
      if(bullishTrend_TF3)
      {
         buyVotes++;
      }
      else if(bearishTrend_TF3)
      {
         sellVotes++;
      }
   }
   
   //--- Require minimum timeframe confirmation
   if(UseMultiTimeframe && tfConfirmed < MinTFConfirmation)
   {
      return 0;
   }
   
   //--- Return signal
   if(buyVotes > sellVotes) return 1;
   else if(sellVotes > buyVotes) return -1;
   
   return 0;
}

//+------------------------------------------------------------------+
//| Get RSI strategy signal                                           |
//+------------------------------------------------------------------+
int GetRSISignal()
{
   int buyVotes = 0;
   int sellVotes = 0;
   
   //--- TF1 RSI
   bool oversold_TF1 = rsi_TF1[0] < RSI_Oversold;
   bool overbought_TF1 = rsi_TF1[0] > RSI_Overbought;
   bool risingFromOversold_TF1 = rsi_TF1[0] > RSI_Oversold && rsi_TF1[1] <= RSI_Oversold;
   bool fallingFromOverbought_TF1 = rsi_TF1[0] < RSI_Overbought && rsi_TF1[1] >= RSI_Overbought;
   
   if(risingFromOversold_TF1 || (oversold_TF1 && rsi_TF1[0] > rsi_TF1[1]))
   {
      buyVotes++;
   }
   else if(fallingFromOverbought_TF1 || (overbought_TF1 && rsi_TF1[0] < rsi_TF1[1]))
   {
      sellVotes++;
   }
   
   //--- TF2 and TF3 confirmation
   if(UseMultiTimeframe)
   {
      if(rsi_TF2[0] < 50 && rsi_TF2[0] > rsi_TF2[1])
         buyVotes++;
      else if(rsi_TF2[0] > 50 && rsi_TF2[0] < rsi_TF2[1])
         sellVotes++;
      
      if(rsi_TF3[0] < 50)
         buyVotes++;
      else if(rsi_TF3[0] > 50)
         sellVotes++;
   }
   
   if(buyVotes > sellVotes) return 1;
   else if(sellVotes > buyVotes) return -1;
   
   return 0;
}

//+------------------------------------------------------------------+
//| Get Bollinger Bands strategy signal                               |
//+------------------------------------------------------------------+
int GetBBSignal()
{
   double currentPrice = iClose(_Symbol, TimeFrame1, 0);
   int buyVotes = 0;
   int sellVotes = 0;
   
   //--- TF1 BB
   bool priceBelowLower_TF1 = currentPrice < bb_lower_TF1[0];
   bool priceAboveUpper_TF1 = currentPrice > bb_upper_TF1[0];
   bool priceRisingFromLower_TF1 = currentPrice > bb_lower_TF1[0] && 
                                    iClose(_Symbol, TimeFrame1, 1) <= bb_lower_TF1[1];
   bool priceFallingFromUpper_TF1 = currentPrice < bb_upper_TF1[0] && 
                                     iClose(_Symbol, TimeFrame1, 1) >= bb_upper_TF1[1];
   
   if(priceRisingFromLower_TF1 || priceBelowLower_TF1)
   {
      buyVotes++;
   }
   else if(priceFallingFromUpper_TF1 || priceAboveUpper_TF1)
   {
      sellVotes++;
   }
   
   //--- TF2 and TF3 confirmation
   if(UseMultiTimeframe)
   {
      if(currentPrice < bb_middle_TF2[0])
         buyVotes++;
      else if(currentPrice > bb_middle_TF2[0])
         sellVotes++;
      
      if(currentPrice < bb_middle_TF3[0])
         buyVotes++;
      else if(currentPrice > bb_middle_TF3[0])
         sellVotes++;
   }
   
   if(buyVotes > sellVotes) return 1;
   else if(sellVotes > buyVotes) return -1;
   
   return 0;
}

//+------------------------------------------------------------------+
//| Get MACD strategy signal                                          |
//+------------------------------------------------------------------+
int GetMACDSignal()
{
   int buyVotes = 0;
   int sellVotes = 0;
   
   //--- TF1 MACD
   bool bullishCross_TF1 = (macd_main_TF1[1] > macd_signal_TF1[1]) && 
                           (macd_main_TF1[2] <= macd_signal_TF1[2]);
   bool bearishCross_TF1 = (macd_main_TF1[1] < macd_signal_TF1[1]) && 
                           (macd_main_TF1[2] >= macd_signal_TF1[2]);
   bool bullish_TF1 = macd_main_TF1[0] > macd_signal_TF1[0] && macd_main_TF1[0] < 0;
   bool bearish_TF1 = macd_main_TF1[0] < macd_signal_TF1[0] && macd_main_TF1[0] > 0;
   
   if(bullishCross_TF1 || bullish_TF1)
   {
      buyVotes++;
   }
   else if(bearishCross_TF1 || bearish_TF1)
   {
      sellVotes++;
   }
   
   //--- TF2 and TF3 confirmation
   if(UseMultiTimeframe)
   {
      if(macd_main_TF2[0] > macd_signal_TF2[0])
         buyVotes++;
      else if(macd_main_TF2[0] < macd_signal_TF2[0])
         sellVotes++;
      
      if(macd_main_TF3[0] > macd_signal_TF3[0])
         buyVotes++;
      else if(macd_main_TF3[0] < macd_signal_TF3[0])
         sellVotes++;
   }
   
   if(buyVotes > sellVotes) return 1;
   else if(sellVotes > buyVotes) return -1;
   
   return 0;
}

//+------------------------------------------------------------------+
//| Execute buy trade                                                  |
//+------------------------------------------------------------------+
void ExecuteBuyTrade(int signalScore)
{
   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double sl = CalculateStopLoss(ORDER_TYPE_BUY, ask);
   double tp = CalculateTakeProfit(ORDER_TYPE_BUY, ask);
   double lots = CalculateLotSize(ask, sl);
   
   //--- Normalize values
   sl = NormalizeDouble(sl, _Digits);
   tp = NormalizeDouble(tp, _Digits);
   lots = NormalizeLot(lots);
   
   //--- Execute trade
   if(trade.Buy(lots, _Symbol, ask, sl, tp, TradeComment + "_S" + IntegerToString(signalScore)))
   {
      ulong ticket = trade.ResultOrder();
      dailyTradeCount++;
      lastTradeTime = TimeCurrent();
      
      //--- Track position
      AddPositionToTracker(ticket, lots, ask, signalScore);
      
      Print("BUY order executed | Ticket: ", ticket, " | Lots: ", lots, 
            " | Price: ", ask, " | SL: ", sl, " | TP: ", tp, " | Score: ", signalScore);
   }
   else
   {
      Print("BUY order failed | Error: ", GetLastError());
   }
}

//+------------------------------------------------------------------+
//| Execute sell trade                                                 |
//+------------------------------------------------------------------+
void ExecuteSellTrade(int signalScore)
{
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double sl = CalculateStopLoss(ORDER_TYPE_SELL, bid);
   double tp = CalculateTakeProfit(ORDER_TYPE_SELL, bid);
   double lots = CalculateLotSize(bid, sl);
   
   //--- Normalize values
   sl = NormalizeDouble(sl, _Digits);
   tp = NormalizeDouble(tp, _Digits);
   lots = NormalizeLot(lots);
   
   //--- Execute trade
   if(trade.Sell(lots, _Symbol, bid, sl, tp, TradeComment + "_S" + IntegerToString(signalScore)))
   {
      ulong ticket = trade.ResultOrder();
      dailyTradeCount++;
      lastTradeTime = TimeCurrent();
      
      //--- Track position
      AddPositionToTracker(ticket, lots, bid, signalScore);
      
      Print("SELL order executed | Ticket: ", ticket, " | Lots: ", lots, 
            " | Price: ", bid, " | SL: ", sl, " | TP: ", tp, " | Score: ", signalScore);
   }
   else
   {
      Print("SELL order failed | Error: ", GetLastError());
   }
}

//+------------------------------------------------------------------+
//| Calculate stop loss                                               |
//+------------------------------------------------------------------+
double CalculateStopLoss(ENUM_ORDER_TYPE orderType, double price)
{
   double sl = 0;
   double slDistance = StopLossPips * GetPipValue();
   
   //--- Use ATR-based SL if enabled
   if(UseATRSizing && atr[0] > 0)
   {
      slDistance = atr[0] * ATR_Multiplier;
   }
   
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
//| Calculate take profit                                             |
//+------------------------------------------------------------------+
double CalculateTakeProfit(ENUM_ORDER_TYPE orderType, double price)
{
   double tp = 0;
   double tpDistance = TakeProfitPips * GetPipValue();
   
   //--- Use ATR-based TP if enabled (2x SL for risk-reward ratio)
   if(UseATRSizing && atr[0] > 0)
   {
      tpDistance = atr[0] * ATR_Multiplier * 2.0;
   }
   
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
//| Calculate lot size based on risk                                  |
//+------------------------------------------------------------------+
double CalculateLotSize(double entryPrice, double stopLoss)
{
   double riskPercent = BaseRiskPercent;
   
   //--- Adjust risk based on win rate if dynamic risk enabled
   if(UseDynamicRisk)
   {
      if(currentWinRate >= 0.65)
         riskPercent = MaxRiskPercent; // Increase risk when winning
      else if(currentWinRate <= 0.45)
         riskPercent = MinRiskPercent; // Decrease risk when losing
   }
   
   //--- Calculate risk amount
   double balance = UseCompounding ? accountInfo.Balance() : accountInfo.Equity();
   double riskAmount = balance * (riskPercent / 100.0);
   
   //--- Calculate lot size
   double slDistance = MathAbs(entryPrice - stopLoss);
   double tickSize = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
   double tickValue = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
   
   if(slDistance == 0 || tickSize == 0)
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
//| Normalize lot size                                                |
//+------------------------------------------------------------------+
double NormalizeLot(double lots)
{
   double minLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   double maxLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
   double lotStep = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
   
   if(MinLotSize > minLot)
      minLot = MinLotSize;
   if(MaxLotSize < maxLot)
      maxLot = MaxLotSize;
   
   lots = MathFloor(lots / lotStep) * lotStep;
   
   if(lots < minLot)
      lots = minLot;
   if(lots > maxLot)
      lots = maxLot;
   
   return NormalizeDouble(lots, 2);
}

//+------------------------------------------------------------------+
//| Get pip value                                                      |
//+------------------------------------------------------------------+
double GetPipValue()
{
   double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
   int digits = (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS);
   
   if(digits == 3 || digits == 5)
      return point * 10;
   else
      return point * 1;
}

//+------------------------------------------------------------------+
//| Manage all open positions                                         |
//+------------------------------------------------------------------+
void ManageAllPositions()
{
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      if(positionInfo.SelectByIndex(i))
      {
         if(positionInfo.Symbol() == _Symbol && positionInfo.Magic() == MagicNumber)
         {
            ulong ticket = positionInfo.Ticket();
            
            //--- Apply position management
            if(UseBreakeven)
               ManageBreakeven(ticket);
            
            if(UsePartialTP)
               ManagePartialTP(ticket);
            
            if(UseTrailingStop)
               ManageTrailingStop(ticket);
         }
      }
   }
   
   //--- Update win rate
   UpdateWinRate();
}

//+------------------------------------------------------------------+
//| Manage breakeven for position                                     |
//+------------------------------------------------------------------+
void ManageBreakeven(ulong ticket)
{
   if(!positionInfo.SelectByTicket(ticket))
      return;
   
   //--- Check if already at breakeven
   int trackerIndex = FindPositionInTracker(ticket);
   if(trackerIndex >= 0 && openPositions[trackerIndex].breakEvenSet)
      return;
   
   double openPrice = positionInfo.PriceOpen();
   double currentSL = positionInfo.StopLoss();
   double currentTP = positionInfo.TakeProfit();
   ENUM_POSITION_TYPE posType = positionInfo.PositionType();
   
   double currentPrice = posType == POSITION_TYPE_BUY ? 
                         SymbolInfoDouble(_Symbol, SYMBOL_BID) : 
                         SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   
   double triggerDistance = BreakevenTriggerPips * GetPipValue();
   double offsetDistance = BreakevenOffsetPips * GetPipValue();
   
   //--- Check if profit reached trigger level
   bool triggerReached = false;
   if(posType == POSITION_TYPE_BUY)
   {
      triggerReached = (currentPrice >= openPrice + triggerDistance);
   }
   else
   {
      triggerReached = (currentPrice <= openPrice - triggerDistance);
   }
   
   if(triggerReached)
   {
      double newSL = posType == POSITION_TYPE_BUY ? 
                     openPrice + offsetDistance : 
                     openPrice - offsetDistance;
      
      newSL = NormalizeDouble(newSL, _Digits);
      
      if(trade.PositionModify(ticket, newSL, currentTP))
      {
         if(trackerIndex >= 0)
            openPositions[trackerIndex].breakEvenSet = true;
         
         Print("Breakeven set for ticket: ", ticket, " | New SL: ", newSL);
      }
   }
}

//+------------------------------------------------------------------+
//| Manage partial take profit                                        |
//+------------------------------------------------------------------+
void ManagePartialTP(ulong ticket)
{
   if(!positionInfo.SelectByTicket(ticket))
      return;
   
   //--- Check if partial TP already taken
   int trackerIndex = FindPositionInTracker(ticket);
   if(trackerIndex >= 0 && openPositions[trackerIndex].partialTPTaken)
      return;
   
   double openPrice = positionInfo.PriceOpen();
   ENUM_POSITION_TYPE posType = positionInfo.PositionType();
   
   double currentPrice = posType == POSITION_TYPE_BUY ? 
                         SymbolInfoDouble(_Symbol, SYMBOL_BID) : 
                         SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   
   double partialTPDistance = PartialTP_Pips * GetPipValue();
   
   //--- Check if partial TP level reached
   bool tpReached = false;
   if(posType == POSITION_TYPE_BUY)
   {
      tpReached = (currentPrice >= openPrice + partialTPDistance);
   }
   else
   {
      tpReached = (currentPrice <= openPrice - partialTPDistance);
   }
   
   if(tpReached)
   {
      double currentVolume = positionInfo.Volume();
      double closeVolume = NormalizeLot(currentVolume * (PartialTP_Percent / 100.0));
      
      if(closeVolume >= SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN))
      {
         if(trade.PositionClosePartial(ticket, closeVolume))
         {
            if(trackerIndex >= 0)
               openPositions[trackerIndex].partialTPTaken = true;
            
            Print("Partial TP taken for ticket: ", ticket, " | Volume: ", closeVolume);
         }
      }
   }
}

//+------------------------------------------------------------------+
//| Manage trailing stop                                              |
//+------------------------------------------------------------------+
void ManageTrailingStop(ulong ticket)
{
   if(!positionInfo.SelectByTicket(ticket))
      return;
   
   double openPrice = positionInfo.PriceOpen();
   double currentSL = positionInfo.StopLoss();
   double currentTP = positionInfo.TakeProfit();
   ENUM_POSITION_TYPE posType = positionInfo.PositionType();
   
   double currentPrice = posType == POSITION_TYPE_BUY ? 
                         SymbolInfoDouble(_Symbol, SYMBOL_BID) : 
                         SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   
   double trailDistance = TrailingStopPips * GetPipValue();
   double trailStep = TrailingStepPips * GetPipValue();
   
   bool shouldModify = false;
   double newSL = currentSL;
   
   if(posType == POSITION_TYPE_BUY)
   {
      newSL = currentPrice - trailDistance;
      
      if(newSL > currentSL + trailStep && newSL > openPrice)
      {
         shouldModify = true;
      }
   }
   else
   {
      newSL = currentPrice + trailDistance;
      
      if((newSL < currentSL - trailStep || currentSL == 0) && newSL < openPrice)
      {
         shouldModify = true;
      }
   }
   
   if(shouldModify)
   {
      newSL = NormalizeDouble(newSL, _Digits);
      
      if(trade.PositionModify(ticket, newSL, currentTP))
      {
         Print("Trailing stop updated for ticket: ", ticket, " | New SL: ", newSL);
      }
   }
}

//+------------------------------------------------------------------+
//| Count own positions                                               |
//+------------------------------------------------------------------+
int CountOwnPositions()
{
   int count = 0;
   
   for(int i = 0; i < PositionsTotal(); i++)
   {
      if(positionInfo.SelectByIndex(i))
      {
         if(positionInfo.Symbol() == _Symbol && positionInfo.Magic() == MagicNumber)
         {
            count++;
         }
      }
   }
   
   return count;
}

//+------------------------------------------------------------------+
//| Get current portfolio risk                                        |
//+------------------------------------------------------------------+
double GetCurrentPortfolioRisk()
{
   double totalRisk = 0.0;
   double balance = accountInfo.Balance();
   
   for(int i = 0; i < PositionsTotal(); i++)
   {
      if(positionInfo.SelectByIndex(i))
      {
         if(positionInfo.Symbol() == _Symbol && positionInfo.Magic() == MagicNumber)
         {
            double openPrice = positionInfo.PriceOpen();
            double sl = positionInfo.StopLoss();
            double volume = positionInfo.Volume();
            
            if(sl != 0)
            {
               double slDistance = MathAbs(openPrice - sl);
               double tickSize = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
               double tickValue = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
               
               double positionRisk = (slDistance / tickSize) * tickValue * volume;
               totalRisk += positionRisk;
            }
         }
      }
   }
   
   return (totalRisk / balance) * 100.0;
}

//+------------------------------------------------------------------+
//| Add position to tracker                                           |
//+------------------------------------------------------------------+
void AddPositionToTracker(ulong ticket, double lots, double price, int score)
{
   if(positionCount < 100)
   {
      openPositions[positionCount].ticket = ticket;
      openPositions[positionCount].breakEvenSet = false;
      openPositions[positionCount].partialTPTaken = false;
      openPositions[positionCount].openTime = TimeCurrent();
      openPositions[positionCount].openPrice = price;
      openPositions[positionCount].initialLots = lots;
      openPositions[positionCount].signalScore = score;
      positionCount++;
   }
}

//+------------------------------------------------------------------+
//| Find position in tracker                                          |
//+------------------------------------------------------------------+
int FindPositionInTracker(ulong ticket)
{
   for(int i = 0; i < positionCount; i++)
   {
      if(openPositions[i].ticket == ticket)
         return i;
   }
   return -1;
}

//+------------------------------------------------------------------+
//| Update win rate                                                    |
//+------------------------------------------------------------------+
void UpdateWinRate()
{
   int totalClosed = 0;
   int winners = 0;
   
   //--- Count closed positions from history
   HistorySelect(0, TimeCurrent());
   
   for(int i = 0; i < HistoryDealsTotal(); i++)
   {
      ulong ticket = HistoryDealGetTicket(i);
      
      if(HistoryDealGetInteger(ticket, DEAL_MAGIC) == MagicNumber &&
         HistoryDealGetString(ticket, DEAL_SYMBOL) == _Symbol &&
         HistoryDealGetInteger(ticket, DEAL_ENTRY) == DEAL_ENTRY_OUT)
      {
         double profit = HistoryDealGetDouble(ticket, DEAL_PROFIT);
         
         if(profit > 0)
            winners++;
         
         totalClosed++;
      }
   }
   
   if(totalClosed > 0)
   {
      currentWinRate = (double)winners / totalClosed;
      totalWins = winners;
      totalTrades = totalClosed;
   }
}

//+------------------------------------------------------------------+
//| Load win rate history                                             |
//+------------------------------------------------------------------+
void LoadWinRateHistory()
{
   //--- Load from file or global variable if available
   if(GlobalVariableCheck("MLQ5_WinRate_" + _Symbol))
   {
      currentWinRate = GlobalVariableGet("MLQ5_WinRate_" + _Symbol);
      Print("Loaded historical win rate: ", DoubleToString(currentWinRate * 100, 2), "%");
   }
}

//+------------------------------------------------------------------+
//| Save win rate history                                             |
//+------------------------------------------------------------------+
void SaveWinRateHistory()
{
   GlobalVariableSet("MLQ5_WinRate_" + _Symbol, currentWinRate);
   Print("Saved win rate: ", DoubleToString(currentWinRate * 100, 2), "%");
}

//+------------------------------------------------------------------+
//| Release all indicator handles                                     |
//+------------------------------------------------------------------+
void ReleaseIndicators()
{
   if(handleFastMA_TF1 != INVALID_HANDLE) IndicatorRelease(handleFastMA_TF1);
   if(handleSlowMA_TF1 != INVALID_HANDLE) IndicatorRelease(handleSlowMA_TF1);
   if(handleFastMA_TF2 != INVALID_HANDLE) IndicatorRelease(handleFastMA_TF2);
   if(handleSlowMA_TF2 != INVALID_HANDLE) IndicatorRelease(handleSlowMA_TF2);
   if(handleFastMA_TF3 != INVALID_HANDLE) IndicatorRelease(handleFastMA_TF3);
   if(handleSlowMA_TF3 != INVALID_HANDLE) IndicatorRelease(handleSlowMA_TF3);
   
   if(handleRSI_TF1 != INVALID_HANDLE) IndicatorRelease(handleRSI_TF1);
   if(handleRSI_TF2 != INVALID_HANDLE) IndicatorRelease(handleRSI_TF2);
   if(handleRSI_TF3 != INVALID_HANDLE) IndicatorRelease(handleRSI_TF3);
   
   if(handleBB_TF1 != INVALID_HANDLE) IndicatorRelease(handleBB_TF1);
   if(handleBB_TF2 != INVALID_HANDLE) IndicatorRelease(handleBB_TF2);
   if(handleBB_TF3 != INVALID_HANDLE) IndicatorRelease(handleBB_TF3);
   
   if(handleMACD_TF1 != INVALID_HANDLE) IndicatorRelease(handleMACD_TF1);
   if(handleMACD_TF2 != INVALID_HANDLE) IndicatorRelease(handleMACD_TF2);
   if(handleMACD_TF3 != INVALID_HANDLE) IndicatorRelease(handleMACD_TF3);
   
   if(handleATR != INVALID_HANDLE) IndicatorRelease(handleATR);
}
//+------------------------------------------------------------------+
