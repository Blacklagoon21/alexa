-- initiate the mqtt client and set keepalive timer to 120sec
mqtt = mqtt.Client(string.format("%d",ChipID), 120,mqttid,mqttpw)
timerCount = 1;
timerCountMax = 8;
heaterIsRun = 0;
autoTracking= 0;
targetTemp = 60;
mqttIsRun = 0;

mqtt:on("connect", function(con) 
	print ("connected") 
	mqttIsRun = 1
	end)
	
mqtt:on("offline", function(con) 
	print ("offline") 
	mqtt_conn() 
	gpio.write(1,gpio.HIGH)
	tmr.unregister(2)
	tmr.unregister(4)
	mqttIsRun = 0
	StrLine1 = "disconnected MQTT"
	display()
end)

-- on receive message
mqtt:on("message", function(conn, topic, data)
  print(topic .. ":" .. data )

  if data ~= nil then
  
	-- DHT11 functions
	if topic == "env/heater/Tcmd" then
		send_temp()
	end

	if topic == "env/heater/autoTracking" then
		if data == "on" then -- heat tracking
			autoTracking= 1;
			StrLine3 = string.format("Auto tracking, %ddeg", targetTemp)
			display()
		else
			autoTracking= 0;
			StrLine3 = "Auto tracking disable"
			display()
		end
	end
	
	if topic == "env/heater/Ttarget" then
		targetTemp = tonumber(data)
		StrLine3 = string.format("Set target temp, %ddeg", targetTemp)
		display()
	end
	
	if topic == "env/heater/timer" then
		if data <= 8 then --Max 8 hours
			timerCountMax = data
		end
	end
	
	-- GPIO functions
	if topic == "env/heater/cmd" then
		heater(data)
	end
  end

end)

function heater(value)
	if value == "off" then
			gpio.write(0,gpio.HIGH)
			mqtt:publish("env/heater/isrun","off",0,0, function(conn) end)
			timerCount = 1
			heaterIsRun=0
			tmr.unregister(3)
			StrLine2 = "Not heating mode"
			display()
	elseif value == "on" then
			gpio.write(0,gpio.LOW)
			mqtt:publish("env/heater/isrun","on",0,0, function(conn) end)
			heaterIsRun=1
			mqtt:publish("env/heater/Rtimer",timerCountMax-timerCount,0,0, function(conn) end)
			StrLine2 = "heating mode"
			display()
			tmr.alarm(3, 30*60*1000, tmr.ALARM_AUTO, function() 
				timerCount = timerCount + 0.5 --30min
				mqtt:publish("env/heater/Rtimer",timerCountMax-timerCount,0,0, function(conn) end)

				StrLine2 = string.format("Timer : %d",timerCountMax-timerCount)
				display()
				--off
				if timerCount == timerCountMax then
					timerCount = 1
					tmr.unregister(3)
					
					gpio.write(0,gpio.HIGH)
					mqtt:publish("env/heater/isrun","off",0,0, function(conn) end)
					StrLine2 = "Timeout ;)"
					display()
				end
			end)
	end	
end

function mqtt_conn()
mqtt:connect(mqttserver, 1883, 0,1, function(conn) 
  mqtt:subscribe("env/heater/cmd",0, function(conn) end)
  mqtt:subscribe("env/heater/Tcmd",0, function(conn) end)
  mqtt:subscribe("env/heater/autoTracking",0, function(conn) end)
  mqtt:subscribe("env/heater/Ttarget",0, function(conn) end)
  
  gpio.write(1,gpio.LOW)
  send_temp()
  --automatically send temp per 10 min
  tmr.alarm(2, 10*60*1000, tmr.ALARM_AUTO, function() 
	send_temp()
  end)
  
  tmr.alarm(4, 10*60*1000, tmr.ALARM_AUTO, function() 
	if TMP175Read() > 70 then
		heater("off")
	end
  end)
  StrLine1 = "Connected MQTT"
  display()
end)
end

function send_temp()
	msg = TMP175Read()
	
	mqtt:publish("env/heater/Tvalue",string.format("%.1f", msg),0,0, function(conn) end)
	if heaterIsRun == 1 then
		mqtt:publish("env/heater/isrun","on",0,0, function(conn) end)
		StrLine3 = string.format("Normal %.1f degrees", msg)
		display()
		if autoTracking == 1 then 
			StrLine3 = string.format("Auto tracking, %.1f/%d", msg,targetTemp)
			display()
			if msg >= targetTemp then
				gpio.write(0,gpio.HIGH)
			elseif msg <= targetTemp-1 then
				gpio.write(0,gpio.LOW)
			end
		end
	else
		StrLine3 = string.format("Normal %.1f degrees", msg)
		display()
		mqtt:publish("env/heater/isrun","off",0,0, function(conn) end)
	end
end

--heater running sw
--gpio.mode(7,gpio.INT,gpio.FLOAT)
--gpio.trig(7, "down", function() -
--	if mqttIsRun == 1 then
--		if heaterIsRun == 1 then
	--		heater("off")
--		else
--			heater("on")
--		end
--	end
--end)