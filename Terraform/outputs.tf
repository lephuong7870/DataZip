# Step 4: Output the generated password
output "generated_password" {
  value = data.external.generate_password.result.password
  sensitive = true  # Mark as sensitive to hide from normal logs
}

# Optional: Output the SHA1 hash (if needed)
output "password_sha1" {
  value = data.external.generate_password.result.sha1
  sensitive = false
}

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
