resource "sdm_node" "sdm-mage-relay" {
  relay {
    name = "${var.app_name}-${var.app_environment}-sdm-relay"
  }
}
