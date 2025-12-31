# WiFi Gate (RouterOS 7.x) - disable WiFi radios until WAN has working Internet

:global WIFIGATEupStreak
:global WIFIGATEdownStreak

:if ([:typeof $WIFIGATEupStreak] = "nothing") do={:set WIFIGATEupStreak 0}
:if ([:typeof $WIFIGATEdownStreak] = "nothing") do={:set WIFIGATEdownStreak 0}

:local logPrefix "WIFIGATE:"
:local debug true
:local wanListName "WAN"
:local checkStarlink true
:local starlinkIp "192.168.100.1"
:local pingTargets {"1.1.1.1"; "8.8.8.8"}
:local pingCount 1
:local pingInterval 500ms
:local pingMinSuccess 1
:local minUpStreak 1
:local minDownStreak 2

:local wanIf ""
:do {
  :local mId [/interface/list/member/find where list=$wanListName]
  :if ([:len $mId] > 0) do={
    :set wanIf [/interface/list/member/get ($mId->0) value-name=interface]
  }
} on-error={:set wanIf ""}

:if ($wanIf = "") do={
  :log warning "$logPrefix No WAN interface found"
  :error "No WAN interface"
}

:if ([:len [/interface/wifi/find]] = 0) do={
  :log warning "$logPrefix No wifi interfaces found"
  :error "No wifi"
}

# Check if Starlink dish is powered on (fast path)
:if ($checkStarlink) do={
  :local dishOn false
  :do {
    :set dishOn ([/ping $starlinkIp count=2] > 0)
  } on-error={:set dishOn false}

  :if (!$dishOn) do={
    :if ($debug) do={:log info "$logPrefix Starlink dish not responding at $starlinkIp"}
    # Dish is off - immediately disable WiFi (no hysteresis needed)
    :if ([:len [/interface/wifi/find where disabled=yes]] < [:len [/interface/wifi/find]]) do={
      :log info "$logPrefix Disabling WiFi radios"
      :do {/interface/wifi/disable [find]} on-error={}
    }
    :set WIFIGATEdownStreak ($WIFIGATEdownStreak + 1)
    :set WIFIGATEupStreak 0
    :return
  }
}

:local hasDefaultRoute false
:do {
  :set hasDefaultRoute ([:len [/ip/route/find where dst-address="0.0.0.0/0" active]] > 0)
} on-error={:set hasDefaultRoute false}

:local pingOk false
:if ($hasDefaultRoute) do={
  :foreach target in=$pingTargets do={
    :local replies 0
    :do {
      :set replies [/ping $target count=$pingCount interval=$pingInterval]
    } on-error={:set replies 0}
    :if ($replies >= $pingMinSuccess) do={:set pingOk true}
  }
}

:local internetUp ($hasDefaultRoute && $pingOk)

:if ($internetUp) do={
  :set WIFIGATEupStreak ($WIFIGATEupStreak + 1)
  :set WIFIGATEdownStreak 0
} else={
  :set WIFIGATEdownStreak ($WIFIGATEdownStreak + 1)
  :set WIFIGATEupStreak 0
}

:local wifiEnabled ([:len [/interface/wifi/find where disabled=no]] > 0)

:if ($debug) do={
  :log info "$logPrefix dish=on WAN=$wanIf route=$hasDefaultRoute pingOk=$pingOk internetUp=$internetUp upStreak=$WIFIGATEupStreak downStreak=$WIFIGATEdownStreak wifiEnabled=$wifiEnabled"
}

:if ($internetUp && $WIFIGATEupStreak >= $minUpStreak) do={
  :if ([:len [/interface/wifi/find where disabled=yes]] = 0) do={} else={
    :log info "$logPrefix Enabling WiFi radios"
    :do {/interface/wifi/enable [find]} on-error={}
  }
}

:if (!$internetUp && $WIFIGATEdownStreak >= $minDownStreak) do={
  :if ([:len [/interface/wifi/find where disabled=yes]] < [:len [/interface/wifi/find]]) do={
    :log info "$logPrefix Disabling WiFi radios"
    :do {/interface/wifi/disable [find]} on-error={}
  }
}
