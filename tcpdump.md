```bash
 Use TCPDUMP to Monitor HTTP Traffic

1. To monitor HTTP traffic including request and response headers and message body:

tcpdump -A -s 0 'tcp port 80 and (((ip[2:2] - ((ip[0]&0xf)<<2)) - ((tcp[12]&0xf0)>>2)) != 0)'

2. To monitor HTTP traffic including request and response headers and message body from a particular source:

tcpdump -A -s 0 'src example.com and tcp port 80 and (((ip[2:2] - ((ip[0]&0xf)<<2)) - ((tcp[12]&0xf0)>>2)) != 0)'

3. To monitor HTTP traffic including request and response headers and message body from local host to local host:

tcpdump -A -s 0 'tcp port 80 and (((ip[2:2] - ((ip[0]&0xf)<<2)) - ((tcp[12]&0xf0)>>2)) != 0)' -i lo

4. To only include HTTP requests, modify “tcp port 80” to “tcp dst port 80” in above commands

5. Capture TCP packets from local host to local host

tcpdump -i lo
```
