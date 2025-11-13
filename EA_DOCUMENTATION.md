# ForexTrader Expert Advisor (EA) Documentation

## Overview

ForexTrader_EA is a fully functional MQL5 Expert Advisor designed based on professional forex trading principles documented in the included trading materials. This EA implements a Moving Average crossover strategy with comprehensive risk management and money management features.

## Trading Strategy

### Core Strategy: Moving Average Crossover

The EA uses a dual Moving Average system as described in the advanced trading course materials:

- **Fast Moving Average (Default: 10 periods)**: Responds quickly to price changes
- **Slow Moving Average (Default: 70 periods)**: Identifies the underlying trend direction

#### Entry Signals

**Buy Signal (Long Entry):**
- Fast MA crosses above Slow MA
- Confirmed by Fast MA remaining above Slow MA on the current bar
- No existing positions open

**Sell Signal (Short Entry):**
- Fast MA crosses below Slow MA
- Confirmed by Fast MA remaining below Slow MA on the current bar
- No existing positions open

## Risk Management Features

### Stop Loss and Take Profit

- **Stop Loss**: Configurable distance in pips (default: 50 pips)
- **Take Profit**: Configurable distance in pips (default: 100 pips)
- Both levels are automatically calculated and set for each trade

### Trailing Stop

- **Optional Feature**: Can be enabled/disabled
- **Trailing Distance**: Configurable (default: 30 pips)
- **Trailing Step**: Minimum price movement before adjustment (default: 10 pips)
- Automatically moves stop loss in profit direction
- Never moves stop loss against the position

## Money Management

### Position Sizing

The EA supports two position sizing methods:

1. **Risk-Based Sizing (Recommended)**
   - Calculates lot size based on account balance and risk percentage
   - Default: Risk 2% of account balance per trade
   - Automatically adjusts position size based on stop loss distance
   
2. **Fixed Lot Sizing**
   - Uses a fixed lot size for all trades
   - Useful for testing or specific trading strategies

### Lot Size Limits

- **Minimum Lot**: Respects broker's minimum lot size
- **Maximum Lot**: Configurable upper limit (default: 10.0 lots)
- **Lot Step**: Automatically normalizes to broker's lot step requirements

## Input Parameters

### Trading Strategy Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| FastMA_Period | Integer | 10 | Period for the fast moving average |
| SlowMA_Period | Integer | 70 | Period for the slow moving average |
| MA_Method | Enum | SMA | MA calculation method (SMA, EMA, SMMA, LWMA) |
| MA_Price | Enum | Close | Price to use for MA calculation |

### Risk Management Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| RiskPercent | Double | 2.0 | Percentage of account balance to risk per trade |
| StopLossPips | Double | 50.0 | Stop loss distance in pips |
| TakeProfitPips | Double | 100.0 | Take profit distance in pips |
| UseTrailingStop | Boolean | true | Enable/disable trailing stop |
| TrailingStopPips | Double | 30.0 | Trailing stop distance in pips |
| TrailingStepPips | Double | 10.0 | Minimum price movement for trailing adjustment |

### Money Management Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| MaxLotSize | Double | 10.0 | Maximum allowed lot size |
| MinLotSize | Double | 0.01 | Minimum allowed lot size |
| UseFixedLot | Boolean | false | Use fixed lot instead of risk-based sizing |
| FixedLotSize | Double | 0.1 | Lot size when using fixed lot mode |

### Trading Hours Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| UseTradingHours | Boolean | false | Limit trading to specific hours |
| StartHour | Integer | 8 | Hour to start trading (0-23) |
| EndHour | Integer | 20 | Hour to stop trading (0-23) |

### Advanced Settings

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| MagicNumber | Integer | 123456 | Unique identifier for EA's trades |
| TradeComment | String | "ForexTrader" | Comment added to all trades |
| Slippage | Integer | 10 | Maximum allowed slippage in points |

## Installation Instructions

### MetaTrader 5 Installation

1. **Copy the EA file**
   - Copy `ForexTrader_EA.mq5` to your MetaTrader 5 data folder
   - Location: `File > Open Data Folder > MQL5 > Experts`

2. **Compile the EA**
   - Open MetaEditor (F4 in MetaTrader 5)
   - Navigate to the Expert folder
   - Double-click `ForexTrader_EA.mq5`
   - Click Compile (F7) or the Compile button
   - Verify compilation succeeds with no errors

3. **Attach to Chart**
   - In MetaTrader 5, open a chart for your desired trading instrument
   - In the Navigator panel, expand "Expert Advisors"
   - Drag `ForexTrader_EA` onto the chart
   - Configure parameters in the popup window
   - Check "Allow automated trading" and "Allow DLL imports" if needed
   - Click OK

## Usage Recommendations

### Recommended Settings for Beginners

```
FastMA_Period: 10
SlowMA_Period: 70
MA_Method: SMA
RiskPercent: 1.0 (Conservative)
StopLossPips: 50
TakeProfitPips: 100
UseTrailingStop: true
UseFixedLot: false
```

### Recommended Instruments

This EA works best on:
- Major forex pairs (EUR/USD, GBP/USD, USD/JPY)
- Timeframes: H1 (1 hour) or H4 (4 hours)
- Markets with clear trending behavior

### Backtesting

Before live trading:
1. Test on demo account for at least 1 month
2. Backtest on historical data (minimum 1 year)
3. Optimize parameters for your specific instrument and timeframe
4. Verify risk management functions correctly

## Trading Principles Implemented

Based on the forex trading documents provided, this EA implements:

1. **Technical Analysis**
   - Moving Average trend indicators
   - Trend identification and confirmation
   - Crossover signal generation

2. **Risk Management**
   - Fixed stop loss on every trade
   - Risk percentage-based position sizing
   - Maximum lot size limits

3. **Money Management**
   - Account balance protection
   - Proportional position sizing
   - Profit protection via trailing stops

4. **Trading Discipline**
   - Automated execution eliminates emotional trading
   - Consistent application of trading rules
   - Optional trading hour restrictions

## Features

✅ **Fully Functional**: Complete trading system ready to use  
✅ **Compilable**: Written in valid MQL5 syntax  
✅ **Risk Management**: Stop loss, take profit, trailing stops  
✅ **Money Management**: Risk-based position sizing  
✅ **Customizable**: All parameters can be adjusted  
✅ **Professional**: Based on documented trading principles  
✅ **Safe**: Multiple safety checks and validations  
✅ **Documented**: Comprehensive inline code comments  

## Safety Features

- Input parameter validation on initialization
- Broker lot size limit compliance
- Position count checking (prevents over-trading)
- Normalized price and lot size values
- Error handling and logging
- Optional trading hour restrictions

## Troubleshooting

### Common Issues

**EA not trading:**
- Verify "Auto Trading" is enabled (button in toolbar)
- Check that trading hours are not restricting trades
- Ensure account has sufficient margin
- Verify the symbol is tradable

**Compilation errors:**
- Ensure you're using MetaTrader 5 (not MT4)
- Check that all MQL5 standard libraries are present
- Update MetaTrader to the latest version

**Wrong lot sizes:**
- Verify RiskPercent is set appropriately (1-5% recommended)
- Check MinLotSize and MaxLotSize settings
- Ensure account balance is sufficient

## License and Disclaimer

**Important Risk Disclosure:**

Trading foreign exchange on margin carries a high level of risk and may not be suitable for all investors. Past performance is not indicative of future results. The high degree of leverage can work against you as well as for you. Before deciding to trade foreign exchange, you should carefully consider your investment objectives, level of experience, and risk appetite.

This Expert Advisor is provided for educational purposes. Use at your own risk. Always test thoroughly on a demo account before live trading.

## Version History

**Version 1.00** (Initial Release)
- Moving Average crossover strategy
- Risk-based position sizing
- Trailing stop functionality
- Trading hour restrictions
- Comprehensive parameter customization

## Support

For questions about the EA functionality or trading strategy, refer to the included forex trading documents:
- Ebook_Forex-A-Z_copy.pdf
- Forex-Trading-For-Beginners-The-Ultimate-Guide_copy.pdf
- Trading_Course_Advanced.pdf

---

**Created based on professional forex trading course materials and industry best practices.**
