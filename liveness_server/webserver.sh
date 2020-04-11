# init sleep before business logic updates status
# typically INIT_WAIT_SECONDS
sleep 10

# start webserver
while true 
do 
   { printf 'HTTP/1.0 200 OK\r\nContent-Length: %d\r\n\r\n' "$(wc -c < /var/tmp/action.status)"; cat /var/tmp/action.status; } | nc -l 8080
done 
