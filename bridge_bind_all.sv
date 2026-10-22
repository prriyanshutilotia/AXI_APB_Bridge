// Keep bridge-specific protocol checks attached to every bridge instance.
bind axi_to_apb_bridge bridge_assert_checker bridge_checks (.*);
