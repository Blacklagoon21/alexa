function TMP175Init()
	sda=5
	scl=6

	-- initialize i2c, set pin1 as sda, set pin2 as scl
	i2c.setup(0, sda, scl, i2c.SLOW)
	
	-- setup TMP175, 12bit resolution(0.0625)
	i2c.start(0)
	i2c.address(0, 0x48, i2c.TRANSMITTER)
	i2c.write(0,1,0x60)
	i2c.stop(0)
	-- change Reg point to read temp
	i2c.start(0)
	i2c.address(0, 0x48, i2c.TRANSMITTER)
	i2c.write(0,0)
	i2c.stop(0)
end

function TMP175Read()
	i2c.start(0)
	i2c.address(0, 0x48, i2c.RECEIVER)
	c = i2c.read(0, 2)
	i2c.stop(0)
	temp1 = string.byte(c)
	temp2 = string.byte(c,2) 
	temp2 = bit.rshift(temp2, 4)
	temp2 = temp2*0.0625
	ret = temp1+temp2
	return ret
end

TMP175Init()
