# frozen_string_literal: true

require_relative 'config.rb'
require_relative 'helpers.rb'
require_relative 'onegate.rb'

def configure_vnf(gw_ipv4 = ONEAPP_VROUTER_ETH1_VIP0 || FALLBACK_GW,
                  use_dns = ONEAPP_VNF_DNS_ENABLED,
                  dns_ipv4 = ONEAPP_VROUTER_ETH1_VIP0 || FALLBACK_DNS)

    if !gw_ipv4.nil? && ipv4?(gw_ipv4)
        msg :info, "Override default GW (#{gw_ipv4})"
        bash "ip route replace default via #{gw_ipv4} dev eth0"
    end

    if use_dns && !dns_ipv4.nil? && ipv4?(dns_ipv4)
        msg :info, "Override primary DNS (#{dns_ipv4})"
        file '/etc/resolv.conf', <<~RESOLV_CONF, overwrite: true
        nameserver #{dns_ipv4}
        RESOLV_CONF
    end
end

def vnf_supervisor_setup_backend(lb_idx = 0,
                                 lb_ipv4 = ONEAPP_VNF_HAPROXY_LB0_IP,
                                 lb_port = ONEAPP_VNF_HAPROXY_LB0_PORT)

    unless (lb_ok = !lb_ipv4.nil? && port?(lb_port))
        msg :error, "Invalid IPv4/port for VNF/HAPROXY/#{lb_idx}, aborting.."
        exit 1
    end

    ipv4 = external_ipv4s
        .reject { |item| item == lb_ipv4 }
        .first

    msg :info, "Register VNF/HAPROXY/#{lb_idx} backend in OneGate"

    onegate_vm_update [
        "ONEGATE_HAPROXY_LB#{lb_idx}_IP=#{lb_ipv4}",
        "ONEGATE_HAPROXY_LB#{lb_idx}_PORT=#{lb_port}",
        "ONEGATE_HAPROXY_LB#{lb_idx}_SERVER_HOST=#{ipv4}",
        "ONEGATE_HAPROXY_LB#{lb_idx}_SERVER_PORT=#{lb_port}"
    ]
end

def vnf_control_plane_setup_backend(lb_idx = 1,
                                    lb_ipv4 = ONEAPP_VNF_HAPROXY_LB1_IP,
                                    lb_port = ONEAPP_VNF_HAPROXY_LB1_PORT)

    unless (lb_ok = !lb_ipv4.nil? && port?(lb_port))
        msg :error, "Invalid IPv4/port for VNF/HAPROXY/#{lb_idx}, aborting.."
        exit 1
    end

    ipv4 = external_ipv4s
        .reject { |item| item == lb_ipv4 }
        .first

    msg :info, "Register VNF/HAPROXY/#{lb_idx} backend in OneGate"

    onegate_vm_update [
        "ONEGATE_HAPROXY_LB#{lb_idx}_IP=#{lb_ipv4}",
        "ONEGATE_HAPROXY_LB#{lb_idx}_PORT=#{lb_port}",
        "ONEGATE_HAPROXY_LB#{lb_idx}_SERVER_HOST=#{ipv4}",
        "ONEGATE_HAPROXY_LB#{lb_idx}_SERVER_PORT=#{lb_port}"
    ]
end

def vnf_ingress_setup_https_backend(lb_idx = 2,
                                    lb_ipv4 = ONEAPP_VNF_HAPROXY_LB2_IP,
                                    lb_port = ONEAPP_VNF_HAPROXY_LB2_PORT)

    unless (lb_ok = !lb_ipv4.nil? && port?(lb_port))
        msg :error, "Invalid IPv4/port for VNF/HAPROXY/#{lb_idx}, aborting.."
        exit 1
    end

    ipv4 = external_ipv4s
        .reject { |item| item == lb_ipv4 }
        .first

    msg :info, "Register VNF/HAPROXY/#{lb_idx} backend in OneGate"

    server_port = lb_port.to_i + 32_000

    onegate_vm_update [
        "ONEGATE_HAPROXY_LB#{lb_idx}_IP=#{lb_ipv4}",
        "ONEGATE_HAPROXY_LB#{lb_idx}_PORT=#{lb_port}",
        "ONEGATE_HAPROXY_LB#{lb_idx}_SERVER_HOST=#{ipv4}",
        "ONEGATE_HAPROXY_LB#{lb_idx}_SERVER_PORT=#{server_port}"
    ]
end

def vnf_ingress_setup_http_backend(lb_idx = 3,
                                   lb_ipv4 = ONEAPP_VNF_HAPROXY_LB3_IP,
                                   lb_port = ONEAPP_VNF_HAPROXY_LB3_PORT)

    unless (lb_ok = !lb_ipv4.nil? && port?(lb_port))
        msg :error, "Invalid IPv4/port for VNF/HAPROXY/#{lb_idx}, aborting.."
        exit 1
    end

    ipv4 = external_ipv4s
        .reject { |item| item == lb_ipv4 }
        .first

    msg :info, "Register VNF/HAPROXY/#{lb_idx} backend in OneGate"

    server_port = lb_port.to_i + 32_000

    onegate_vm_update [
        "ONEGATE_HAPROXY_LB#{lb_idx}_IP=#{lb_ipv4}",
        "ONEGATE_HAPROXY_LB#{lb_idx}_PORT=#{lb_port}",
        "ONEGATE_HAPROXY_LB#{lb_idx}_SERVER_HOST=#{ipv4}",
        "ONEGATE_HAPROXY_LB#{lb_idx}_SERVER_PORT=#{server_port}"
    ]
end
