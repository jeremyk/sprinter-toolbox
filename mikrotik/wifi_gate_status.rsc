# WiFi Gate Status - Debug script to show current state
# Run with: /system/script/run wifi_gate_status

:global WIFIGATEupStreak
:global WIFIGATEdownStreak

:put "=== WiFi Gate Status ==="
:put ""

# Global state
:put "--- Globals ---"
:put ("upStreak:   " . [:tostr $WIFIGATEupStreak])
:put ("downStreak: " . [:tostr $WIFIGATEdownStreak])
:put ""

# WiFi interfaces
:put "--- WiFi Interfaces ---"
:local wifiTotal [:len [/interface/wifi/find]]
:local wifiEnabled [:len [/interface/wifi/find where disabled=no]]
:local wifiDisabled [:len [/interface/wifi/find where disabled=yes]]
:put ("Total:    " . [:tostr $wifiTotal])
:put ("Enabled:  " . [:tostr $wifiEnabled])
:put ("Disabled: " . [:tostr $wifiDisabled])
:foreach iface in=[/interface/wifi/find] do={
  :local name [/interface/wifi/get $iface name]
  :local disabled [/interface/wifi/get $iface disabled]
  :local status "enabled"
  :if ($disabled) do={:set status "DISABLED"}
  :put ("  " . $name . ": " . $status)
}
:put ""

# WAN interface
:put "--- WAN Interface ---"
:local wanListName "WAN"
:local wanIf ""
:do {
  :local mId [/interface/list/member/find where list=$wanListName]
  :if ([:len $mId] > 0) do={
    :set wanIf [/interface/list/member/get ($mId->0) value-name=interface]
  }
} on-error={}
:if ($wanIf != "") do={
  :local running [/interface/get [find name=$wanIf] running]
  :put ("Interface: " . $wanIf)
  :put ("Running:   " . [:tostr $running])
} else={
  :put "Interface: NOT FOUND"
}
:put ""

# Default route
:put "--- Routing ---"
:local defaultRoutes [/ip/route/find where dst-address="0.0.0.0/0" active]
:put ("Active default routes: " . [:tostr [:len $defaultRoutes]])
:foreach r in=$defaultRoutes do={
  :local gw [/ip/route/get $r gateway]
  :local dist [/ip/route/get $r distance]
  :put ("  gateway=" . [:tostr $gw] . " distance=" . [:tostr $dist])
}
:put ""

# Starlink dish
:put "--- Starlink Dish ---"
:local starlinkIp "192.168.100.1"
:local dishPing [/ping $starlinkIp count=1]
:if ($dishPing > 0) do={
  :put ("Ping " . $starlinkIp . ": OK")
} else={
  :put ("Ping " . $starlinkIp . ": FAILED (dish off?)")
}
:put ""

# Internet connectivity
:put "--- Internet Connectivity ---"
:local targets {"1.1.1.1"; "8.8.8.8"}
:foreach t in=$targets do={
  :local result [/ping $t count=1]
  :if ($result > 0) do={
    :put ("Ping " . $t . ": OK")
  } else={
    :put ("Ping " . $t . ": FAILED")
  }
}
:put ""
:put "=== End Status ==="
