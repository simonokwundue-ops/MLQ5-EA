# Quick Installation Guide - ForexTrader EA

## Prerequisites

- MetaTrader 5 platform installed
- Active trading account (demo or live)
- Basic understanding of forex trading

## Installation Steps

### Step 1: Locate Your MT5 Data Folder

1. Open MetaTrader 5
2. Click **File → Open Data Folder**
3. A Windows Explorer window will open

### Step 2: Copy the EA File

1. Navigate to **MQL5 → Experts** folder
2. Copy `ForexTrader_EA.mq5` into this folder
3. Keep the folder open for the next step

### Step 3: Compile the EA

1. In MetaTrader 5, press **F4** to open MetaEditor
2. In the Navigator panel (left side), expand **Experts**
3. Double-click **ForexTrader_EA.mq5** to open it
4. Click the **Compile** button (or press F7)
5. Check the "Toolbox" panel at the bottom:
   - ✅ **Success**: "0 error(s), 0 warning(s)"
   - ❌ **Failed**: Review error messages

### Step 4: Enable Auto Trading

1. Return to MetaTrader 5 main window
2. Click the **Algo Trading** button in the toolbar
   - It should turn **green** when enabled
   - If red, click it to enable automated trading

### Step 5: Attach EA to Chart

1. Open a chart for your desired instrument (e.g., EUR/USD)
2. Set your preferred timeframe (H1 or H4 recommended)
3. In the **Navigator** panel, expand **Expert Advisors**
4. **Drag and drop** ForexTrader_EA onto the chart
5. A settings window will appear

### Step 6: Configure Parameters

#### Recommended Settings for Beginners:

**Trading Strategy:**
- Fast MA Period: `10`
- Slow MA Period: `70`
- MA Method: `Simple`

**Risk Management:**
- Risk Percent: `1.0` (1% - conservative)
- Stop Loss Pips: `50`
- Take Profit Pips: `100`
- Use Trailing Stop: `Yes`

**Money Management:**
- Use Fixed Lot: `No` (uses risk-based sizing)

Click **OK** to apply settings.

### Step 7: Verify EA is Running

1. Look at the top-right corner of your chart
2. You should see a **smiling face icon** 😊
   - 😊 = EA is active and working
   - 😐 = EA is loaded but auto trading disabled
   - ❌ = EA error or not loaded

3. Check the **Experts** tab (Toolbox panel at bottom)
   - You should see initialization messages
   - "ForexTrader EA initialized successfully"

## Testing Before Live Trading

### Demo Account Testing (REQUIRED)

1. **Open a demo account** if you don't have one
2. **Run the EA for at least 2 weeks**
3. **Monitor performance** daily
4. **Verify all features** work correctly:
   - Trades open at MA crossovers
   - Stop loss and take profit are set
   - Trailing stop activates when in profit

### Strategy Tester (Backtesting)

1. In MT5, press **Ctrl + R** to open Strategy Tester
2. Select **ForexTrader_EA** from the Expert Advisor dropdown
3. Choose your symbol (e.g., EUR/USD)
4. Select timeframe (H1 or H4)
5. Set test period (at least 6 months)
6. Click **Start** to run backtest
7. Review results and equity curve

## Monitoring Your EA

### What to Watch

- **Open positions**: Check trade direction and lot sizes
- **Journal tab**: Look for any error messages
- **Account balance**: Monitor for unexpected changes
- **Experts tab**: Review EA's log messages

### Warning Signs

⚠️ **Stop the EA immediately if:**
- Lot sizes are unexpectedly large
- Multiple positions open simultaneously (EA only opens 1)
- Stop losses are not being set
- Error messages appear repeatedly

## Troubleshooting

### EA Not Opening Trades

**Check:**
- ✅ Auto Trading is enabled (green button)
- ✅ Chart timeframe matches your strategy
- ✅ Market is open (not weekend)
- ✅ Account has sufficient free margin
- ✅ No MA crossover has occurred recently

### Compilation Errors

**Solutions:**
- Update MetaTrader 5 to latest version
- Verify you're using MT5 (not MT4)
- Check file encoding is UTF-8
- Restart MetaEditor

### Wrong Position Sizes

**Verify:**
- Risk Percent is reasonable (1-5%)
- Min/Max Lot Size settings
- Account balance is sufficient
- Broker's minimum lot size requirements

## Common Settings Adjustments

### More Conservative (Lower Risk)
```
Risk Percent: 0.5 - 1.0%
Stop Loss: 60-80 pips
```

### More Aggressive (Higher Risk)
```
Risk Percent: 3.0 - 5.0%
Stop Loss: 30-40 pips
Take Profit: 60-80 pips
```

### Different Timeframes

**For H4 timeframe:**
```
Fast MA: 10
Slow MA: 70
Stop Loss: 80 pips
Take Profit: 160 pips
```

**For M15 timeframe:**
```
Fast MA: 10
Slow MA: 70
Stop Loss: 20 pips
Take Profit: 40 pips
```

## Safety Reminders

1. ⚠️ **Always test on demo first**
2. ⚠️ **Start with minimum risk (1% or less)**
3. ⚠️ **Never risk more than you can afford to lose**
4. ⚠️ **Monitor the EA regularly**
5. ⚠️ **Keep MetaTrader running when EA is active**

## Getting Help

### Check These First:
1. **EA_DOCUMENTATION.md** - Comprehensive guide
2. **Experts tab** - EA log messages
3. **Journal tab** - MetaTrader system messages

### Common Questions:

**Q: Why isn't the EA trading?**
A: The EA only trades when a MA crossover occurs. This might take hours or days depending on market conditions.

**Q: Can I run multiple EAs?**
A: Yes, but use different Magic Numbers for each EA.

**Q: Does my computer need to stay on?**
A: Yes, MT5 must be running for the EA to trade. Consider using a VPS for 24/7 operation.

**Q: What happens during weekends?**
A: The forex market is closed. The EA will not trade but will resume Monday when markets open.

---

## Next Steps

After successful installation:

1. ✅ **Read EA_DOCUMENTATION.md** for detailed parameter explanations
2. ✅ **Backtest the EA** on historical data
3. ✅ **Run on demo** for at least 2 weeks
4. ✅ **Study the forex materials** included in the repository
5. ✅ **Start with small position sizes** when going live

**Remember**: This EA is a tool to assist your trading. Always maintain proper risk management and never invest more than you can afford to lose.

---

**Good luck with your automated trading! 📈**
