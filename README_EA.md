# ForexMasterEA - Professional Trading Expert Advisor

## Overview

ForexMasterEA is a fully functional MQL5 Expert Advisor designed based on professional forex trading principles extracted from comprehensive forex educational materials. This EA implements a disciplined, human-like trading approach that mirrors the knowledge, professionalism, and strategies taught in professional forex trading courses.

## Trading Strategy

### Core Strategy: Moving Average Crossover

The EA uses a classic and proven Moving Average crossover strategy:

- **Fast Moving Average**: Default 10-period EMA
- **Slow Moving Average**: Default 30-period EMA

**Buy Signal**: Generated when the fast MA crosses above the slow MA from below, indicating an upward trend.

**Sell Signal**: Generated when the fast MA crosses below the slow MA from above, indicating a downward trend.

### Trend Strength Confirmation: ADX (Average Directional Index)

The EA includes an optional ADX filter to confirm trend strength before entering trades:

- **ADX Indicator**: 14-period (default)
- **Minimum ADX Level**: 20 (default)

The ADX filter ensures that trades are only taken when there is a strong, developing trend, avoiding false signals during consolidation periods.

## Risk Management

ForexMasterEA implements professional risk management principles:

### Position Sizing

- **Dynamic Risk-Based Sizing**: Calculates lot size based on a percentage of account balance (default 2%)
- **Fixed Lot Option**: Option to use a fixed lot size for consistent position sizing
- **Risk Per Trade**: Configurable risk percentage (default 2% of balance)

### Stop Loss & Take Profit

- **Stop Loss**: Configurable in pips (default 50 pips)
- **Take Profit**: Configurable in pips (default 100 pips)
- **Risk-Reward Ratio**: Default 1:2 (risking 50 pips to gain 100 pips)

### Spread Filter

- **Maximum Spread**: Configurable maximum spread in pips (default 3 pips)
- Prevents trading during high spread conditions

## Money Management

The EA follows professional money management rules:

- **Minimum Lot Size**: 0.01 (configurable)
- **Maximum Lot Size**: 10.0 (configurable)
- **Lot Normalization**: Automatically adjusts lot sizes to meet broker requirements
- **Balance Protection**: Limits position size to protect account balance

## Input Parameters

### Moving Average Strategy
| Parameter | Default | Description |
|-----------|---------|-------------|
| FastMA_Period | 10 | Period for fast moving average |
| SlowMA_Period | 30 | Period for slow moving average |
| MA_Method | EMA | Type of moving average (SMA, EMA, SMMA, LWMA) |
| MA_AppliedPrice | PRICE_CLOSE | Price to apply MA to |

### Trend Strength Confirmation
| Parameter | Default | Description |
|-----------|---------|-------------|
| UseADX | true | Enable/disable ADX filter |
| ADX_Period | 14 | Period for ADX calculation |
| ADX_MinLevel | 20.0 | Minimum ADX value for trade entry |

### Risk Management
| Parameter | Default | Description |
|-----------|---------|-------------|
| RiskPercent | 2.0 | Risk per trade as % of balance |
| StopLossPips | 50.0 | Stop loss distance in pips |
| TakeProfitPips | 100.0 | Take profit distance in pips |
| MaxSpreadPips | 3.0 | Maximum allowed spread in pips |

### Money Management
| Parameter | Default | Description |
|-----------|---------|-------------|
| MinLotSize | 0.01 | Minimum lot size allowed |
| MaxLotSize | 10.0 | Maximum lot size allowed |
| UseFixedLot | false | Use fixed lot size instead of dynamic |
| FixedLotSize | 0.1 | Fixed lot size (if enabled) |

### Trading Hours
| Parameter | Default | Description |
|-----------|---------|-------------|
| UseTradingHours | false | Enable trading hours filter |
| StartHour | 8 | Start trading hour (server time) |
| EndHour | 20 | End trading hour (server time) |

### EA Settings
| Parameter | Default | Description |
|-----------|---------|-------------|
| MagicNumber | 123456 | Unique identifier for EA trades |
| TradeComment | "ForexMasterEA" | Comment added to trades |

## Installation

1. Copy `ForexMasterEA.mq5` to your MetaTrader 5 terminal's `MQL5/Experts` folder
2. Compile the EA in MetaEditor (press F7 or click Compile)
3. Restart MetaTrader 5 or refresh the Navigator panel
4. Drag and drop the EA onto your desired chart
5. Configure input parameters as needed
6. Enable AutoTrading in MetaTrader 5

## Usage Recommendations

### For Beginners

Start with conservative settings:
- Risk Percent: 1.0%
- Stop Loss: 50 pips
- Take Profit: 100 pips
- Use Fixed Lot: Yes (0.01 lots on micro accounts)
- Enable ADX filter: Yes

### For Experienced Traders

Optimize based on your strategy:
- Adjust MA periods based on backtesting results
- Fine-tune ADX levels for your preferred market conditions
- Set risk percent according to your risk tolerance
- Customize trading hours to match optimal market sessions

### Best Practices

1. **Backtest First**: Always backtest the EA on historical data before live trading
2. **Start Small**: Begin with minimum lot sizes or a demo account
3. **Monitor Regularly**: Check the EA's performance regularly
4. **Optimize Parameters**: Adjust parameters based on market conditions and performance
5. **Risk Management**: Never risk more than you can afford to lose
6. **Diversify**: Don't rely on a single EA or strategy

## Currency Pairs

The EA can trade any currency pair, but it performs best on:

- Major pairs (EURUSD, GBPUSD, USDJPY, USDCHF)
- Pairs with low spreads and good liquidity
- Trending markets rather than ranging markets

## Timeframes

The EA can work on any timeframe, recommended timeframes:

- **H1 (1 Hour)**: Good balance between signals and reliability
- **H4 (4 Hours)**: Fewer signals but higher quality
- **D1 (Daily)**: Best for swing trading

## Features

✅ Professional Moving Average crossover strategy  
✅ ADX trend strength confirmation  
✅ Dynamic position sizing based on account risk  
✅ Configurable stop loss and take profit  
✅ Spread filter to avoid high-cost trades  
✅ Trading hours filter for optimal trading times  
✅ Comprehensive error handling and logging  
✅ One trade at a time to maintain discipline  
✅ Fully customizable input parameters  
✅ Complies with MQL5 best practices  

## Trading Principles Implemented

Based on the forex educational materials in this repository, the EA implements:

1. **Discipline**: Follows a strict set of rules without emotional decision-making
2. **Risk Management**: Never risks more than specified percentage per trade
3. **Trend Following**: Identifies and follows market trends using MA crossovers
4. **Confirmation**: Uses ADX to confirm trend strength
5. **Money Management**: Proper position sizing and lot management
6. **Professional Approach**: Mirrors a human trader who has mastered forex fundamentals

## Compilation

To compile the EA:

```bash
# In MetaEditor
Press F7 or click Compile button

# Or via command line (if MetaEditor command line is available)
metaeditor64.exe /compile:"ForexMasterEA.mq5"
```

## Testing

### Strategy Tester

1. Open MetaTrader 5
2. Press Ctrl+R to open Strategy Tester
3. Select ForexMasterEA from Expert Advisors list
4. Choose your symbol and timeframe
5. Set testing period
6. Configure parameters
7. Run the test

### Recommended Testing Parameters

- Period: At least 1 year of historical data
- Model: Every tick based on real ticks
- Optimization: Generic algorithm
- Forward testing: 20-30% of data

## Disclaimer

**Important**: Trading forex involves substantial risk of loss and is not suitable for all investors. Past performance is not indicative of future results. This Expert Advisor is provided for educational purposes. Always test on a demo account before using real funds.

## Support and Contributions

This EA is part of the MLQ5-EA project. For questions, issues, or contributions:

- Repository: https://github.com/simonokwundue-ops/MLQ5-EA
- Issues: Please report bugs or request features via GitHub issues

## Version History

### Version 1.00 (Initial Release)
- Moving Average crossover strategy implementation
- ADX trend strength filter
- Professional risk management system
- Dynamic position sizing
- Comprehensive input parameters
- Trading hours filter
- Spread filter
- Full MQL5 compatibility

## License

This project is open source. Please refer to the repository for license details.

## Educational Resources

This EA was developed based on the following forex educational materials included in this repository:

- Ebook_Forex-A-Z_copy.pdf
- Forex-Trading-For-Beginners-The-Ultimate-Guide_copy.pdf
- Trading_Course_Advanced.pdf

These materials cover essential topics including:
- Forex market fundamentals
- Technical indicators (Moving Averages, ADX, Oscillators)
- Risk and money management
- Trading psychology
- Chart analysis and patterns

We recommend reading these materials to understand the principles implemented in this EA.
