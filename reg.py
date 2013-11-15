import time
import serial

ser = serial.Serial(port=29, baudrate=9600, bytesize=serial.EIGHTBITS, parity=serial.PARITY_NONE, stopbits=serial.STOPBITS_TWO, timeout=1) 
ser.isOpen()
connected=False

cash_reg = []
my_dict = []

reg = ['@r3', '@r1', '@r2', '@r4']	
flag = 1
start_rec = 0
wrong_id = 0
start_count = 0
barcode_flag = 0

def handle_data(data):
    print(data)

print 'start transmission'
while 1 :
	for item in reg:
		try:
			send_pkg = item+'/'
			ser.write(send_pkg)
			print 'sending '+ send_pkg
			while flag :
			
				start_count += 1
				buffer = ser.read()	#blocking call
				print 'received '+buffer
				if start_rec == 1:
					if buffer == item[1] :
						barcode_flag = 1
				if buffer == '/' :
					#print 'end round'
					flag = 0
					break
				if buffer == '@' :
					start_rec = 1
				if buffer == '0' :
					if start_rec == 1:
						start_rec = 0
						wrong_id = 1
						print 'wrong id'
				if start_count == 5 :
					start_count = 0
					flag = 0
					break
					
			start_rec = 0
			wrong_id = 0
			flag = 1
			start_count = 0
		except SerialTimeoutException:
			print 'Serial time out'
			continue
