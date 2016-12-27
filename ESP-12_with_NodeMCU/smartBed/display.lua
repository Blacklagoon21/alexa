

function displayInit()
	-- initialize i2c, set pin1 as sda, set pin2 as scl
	i2c.setup(0, 5, 6, i2c.SLOW)
	disp = u8g.ssd1306_128x64_i2c(0x3c)
	disp:setFont(u8g.font_6x10)
	disp:setFontRefHeightExtendedText()
	disp:setDefaultForegroundColor()
	disp:setFontPosTop()
end

function clear()

end

function draw()
   disp:setFont(u8g.font_6x10)
   disp:drawStr( 0, 10, " SmartBed with Alexa")
   disp:drawLine(0, 22, 128, 22);
   
   disp:drawStr( 0, 30, StrLine1) 
   disp:drawStr( 0, 40, StrLine2) 
   disp:drawStr( 0, 50, StrLine3) 
end

function display()
  disp:firstPage()
  repeat
       draw()
  until disp:nextPage() == false      
end
displayInit()
display()
