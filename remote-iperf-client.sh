# iperf2 needs to set the TCP window size consistently on BOTH the server and client sides

# iperf2 with TCP window size 50k bits
iperf -c -p 5050 -w 50k

# iperf2 with TCP window size 100k bits
iperf -c -p 5100 -w 100k

# iperf2 with TCP window size 200k bits
iperf -c -p 5200 -w 200k

# iperf2 with TCP window size 500k bits
iperf -c -p 5500 -w 500k

# iperf3 has no option to set the TCP window size on the server side. Only the client side can.
# iperf3 with TCP window size 50k bits
iperf3 -c  -w 50k

# iperf3 with TCP window size 100k bits
iperf3 -c  -w 100k

# iperf3 with TCP window size 200k bits
iperf3 -c  -w 200k

# iperf3 with TCP window size 500k bits
iperf3 -c  -w 500k

