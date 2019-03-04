# iperf2 needs to set the TCP window size consistently on BOTH the server and client sides

# iperf2 with TCP window size 50k bits
iperf -s -p 5050 -w 50k

# iperf2 with TCP window size 100k bits
iperf -s -p 5100 -w 100k

# iperf2 with TCP window size 200k bits
iperf -s -p 5200 -w 200k

# iperf2 with TCP window size 500k bits
iperf -s -p 5500 -w 500k

# iperf 3 has no option to set the TCP window size on the server side. Only the client side can.
# Listening on the default port 5201
iperf3 -s
