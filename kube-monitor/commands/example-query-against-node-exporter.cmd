# disk io utilization panel
irate(node_disk_io_time_seconds_total{job='node',instance='$instance',device!~'^(md\\d+$|dm-)'}[5m]) 
