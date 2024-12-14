#  Output the Clickhouse Ip and Port
output "clickhouse_node_port" {
  value = data.external.clickhouse_service_details.result.node_port
}

output "clickhouse_node_ip" {
  value = data.external.clickhouse_service_details.result.node_ip
}


#  Output the SuperSet service details
output "superset_node_ip" {
  value = data.external.superset_service_details.result.node_ip
}

output "superset_node_port" {
  value = data.external.superset_service_details.result.node_port
}
