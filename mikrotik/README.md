# MikroTik Scripts

## wifi_gate_status.rsc

Debug script that prints the current status of all WiFi Gate globals and connectivity info.

```routeros
/system/script/run wifi_gate_status
```

Output includes:
- Global variables (upStreak, downStreak)
- WiFi interface status (enabled/disabled for each)
- WAN interface info
- Active default routes
- Starlink dish ping
- Internet connectivity pings

---

## wifi_gate_on_wan.rsc

Disables WiFi radios when WAN internet connectivity is lost, so devices automatically fall back to cellular. Re-enables WiFi when connectivity returns.

### Use Case

Mobile/RV setup with Starlink that gets turned on/off or loses connectivity under trees. When there's no internet, disabling WiFi forces phones to use cellular instead of staying connected to a dead WiFi network.

### Features

- **Starlink dish detection**: Pings dish directly (192.168.100.1) for fast detection when powered off
- **Dual ping targets**: Tests 1.1.1.1 and 8.8.8.8 - either succeeding = internet up
- **Hysteresis**: Configurable up/down streak thresholds to avoid flapping
- **Immediate disable on dish off**: No hysteresis when Starlink dish is powered off

### Configuration

Edit the variables at the top of the script:

```routeros
:local debug true           # Enable verbose logging
:local checkStarlink true   # Enable Starlink dish check
:local starlinkIp "192.168.100.1"
:local pingTargets {"1.1.1.1"; "8.8.8.8"}
:local pingCount 2
:local pingInterval 500ms
:local pingMinSuccess 1
:local minUpStreak 1        # Checks before enabling WiFi
:local minDownStreak 2      # Checks before disabling WiFi
```

### Commands

**View logs:**
```routeros
/log/print where message~"WIFIGATE:"
```

**Run manually:**
```routeros
/system/script/run wifi_gate_on_wan
```

**Import script:**
```routeros
/system/script/add name=wifi_gate_on_wan source=[/file/get wifi_gate_on_wan.rsc contents]
```

Or paste the script contents directly:
```routeros
/system/script/add name=wifi_gate_on_wan source={
  # paste script here
}
```

### Scheduling

**Create scheduler (runs every 10 seconds):**
```routeros
/system/scheduler/add name=wifi_gate_on_wan interval=10s on-event="/system/script/run wifi_gate_on_wan"
```

**View current schedule:**
```routeros
/system/scheduler/print where name~"wifi"
```

**Update interval:**
```routeros
/system/scheduler/set [find name="wifi_gate_on_wan"] interval=5s
```

**Disable/enable scheduler:**
```routeros
/system/scheduler/disable [find name="wifi_gate_on_wan"]
/system/scheduler/enable [find name="wifi_gate_on_wan"]
```

### Timing Considerations

| Interval | Response Time (with downStreak=2) |
|----------|-----------------------------------|
| 5s       | 10s to disable                    |
| 10s      | 20s to disable                    |
| 15s      | 30s to disable                    |

The script takes ~3-6 seconds to run (ping time), so don't set interval below 5s.
