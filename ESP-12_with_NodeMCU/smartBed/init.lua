--Get default values
ChipID = node.chipid()

StrLine1 = "Waiting MQTT server"
StrLine2 = "Not heating mode"
StrLine3 = ""
--Init system
uart.setup(0,9600,8,0,1,0)
gpio.mode(2,gpio.OUTPUT)
gpio.write(2,gpio.HIGH)
gpio.mode(1,gpio.OUTPUT)
gpio.write(1,gpio.HIGH)
gpio.mode(0,gpio.OUTPUT)
gpio.write(0,gpio.HIGH)

function blink_led(value)
	if value == 1 then
		gpio.write(2,gpio.LOW)
	else
		gpio.write(2,gpio.HIGH)
	end
end

--Load wifi set
dofile("wifi.lua")
dofile("mqttserver.lua")

--Init functions
dofile("dht_mqtt.lua")
dofile("tmp175.lua")
dofile("display.lua")
 
--TCP IP Service
srv = net.createServer(net.TCP)
--Network Setting
wifi.eventmon.register(wifi.eventmon.STA_CONNECTED, function(T) 
 print("\n\tSTA - CONNECTED".."\n\tSSID: "..T.SSID.."\n\tBSSID: "..T.BSSID.."\n\tChannel: "..T.channel)
 
 end)
 
-- reconnect WiFi
wifi.eventmon.register(wifi.eventmon.STA_DISCONNECTED, function(T) 
 print("\n\tSTA - DISCONNECTED".."\n\tSSID: "..T.SSID.."\n\tBSSID: "..
 T.BSSID.."\n\treason: "..T.reason)
 wifi.sta.connect()
 tmr.start(1)
 end)
 
-- connect WiFi 
wifi.setmode(wifi.STATION)
wifi.setphymode(wifi.PHYMODE_B) -- for low current
wifi.sta.config(WIFISSID,WIFIPASS)
wifi.sta.connect()
lamp=false
tmr.alarm(1, 500, 1, function()
  if wifi.sta.status()== 1 then
    if lamp == false then
	  lamp = true
	  gpio.write(2,gpio.HIGH)
	else
	  lamp = false
	  gpio.write(2,gpio.LOW)
	end
 else
  tmr.stop(1)
  gpio.write(2,gpio.LOW)
  print("\tESP8266 mode: " .. wifi.getmode())
  print("\tMAC address: " .. wifi.ap.getmac())
  print("\tIP: "..wifi.sta.getip())
  mqtt_conn()
  --http_init()
  end
end)

--dofile("srv.lua")
