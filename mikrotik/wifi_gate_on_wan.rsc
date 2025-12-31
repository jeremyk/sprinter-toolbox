# WiFi Gate (RouterOS 7.x) - disable WiFi radios until WAN has working Internet
# Log prefix: WIFIGATE:
# /log/print where message~"WIFIGATE:"

:global WIFIGATEupStreak
:global WIFIGATEdownStreak
:global WIFIGATElastState

:if ([:typeof $WIFIGATEupStreak] = "nothing") do={:set WIFIGATEupStreak 0}
:if ([:typeof $WIFIGATEdownStreak] = "nothing") do={:set WIFIGATEdownStreak 0}
:if ([:typeof $WIFIGATElastState] = "nothing") do={:set WIFIGATElastState "unknown"}

:local prefix "WIFIGATE:"
:local wanListName "WAN"
:local pingTarget "1.1.1.1"
:local pingCount 3
:local pingMinSuccess 2
:local minUpStreak 2
:local minDownStreak 2

:local wanIf ""
:do {
  :local mId [/interface/list/member/find where list=$wanListName]
  :if ([:len $mId] > 0) do={
    :set wanIf [/interface/list/member/get ($mId->0) value-name=interface]
  }
} on-error={:set wanIf ""}

:if ($wanIf = "") do={
  :log warning "$prefix No WAN interface found"
  :error "No WAN interface"
}

:local hasDefaultRoute false
:do {
  :set hasDefaultRoute ([:len [/ip/route/find where dst-address="0.0.0.0/0" active]] > 0)
} on-error={:set hasDefaultRoute false}

:local pingOk false
:local pingReplies 0
:if ($hasDefaultRoute) do={
  :do {
    :set pingReplies [/ping $pingTarget count=$pingCount]
    :set pingOk ($pingReplies >= $pingMinSuccess)
  } on-error={
    :set pingReplies 0
    :set pingOk false
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

:log info "$prefix WAN=$wanIf route=$hasDefaultRoute ping=$pingReplies/$pingCount internetUp=$internetUp upStreak=$WIFIGATEupStreak downStreak=$WIFIGATEdownStreak last=$WIFIGATElastState"

:local hasWifi false
:do {
  :set hasWifi ([:len [/interface/wifi/find]] > 0)
} on-error={}

:if (!$hasWifi) do={
  :log warning "$prefix No wifi interfaces found"
  :error "No wifi"
}

:if ($internetUp && $WIFIGATEupStreak >= $minUpStreak && $WIFIGATElastState != "enabled") do={
  :log info "$prefix Enabling WiFi radios"
  :do {/interface/wifi/enable [find]} on-error={:log warning "$prefix Failed to enable wifi"}
  :set WIFIGATElastState "enabled"
}

:if (!$internetUp && $WIFIGATEdownStreak >= $minDownStreak && $WIFIGATElastState != "disabled") do={
  :log info "$prefix Disabling WiFi radios"
  :do {/interface/wifi/disable [find]} on-error={:log warning "$prefix Failed to disable wifi"}
  :set WIFIGATElastState "disabled"
}