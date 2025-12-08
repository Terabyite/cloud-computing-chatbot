output "alb_dns_name" {
  value = module.alb.alb_dns_name
}

output "app_url" {
  value = (
    var.hosted_zone_name == "" ?
    "http://${module.alb.alb_dns_name}" :
    format(
      "https://%s",
      (
        var.app_subdomain == "" ?
        var.hosted_zone_name :
        "${var.app_subdomain}.${var.hosted_zone_name}"
      )
    )
  )

  description = "Open this URL to reach your chatbot"
}
