# Observability Stack

Docker Compose based observability stack running on Colima.

## Components

- Prometheus
- Grafana
- Node Exporter
- Blackbox Exporter
- Alertmanager

## Architecture

```text
                    Grafana
                     :3000
                       |
                       v
                  Prometheus
                    :9090
                  /    |    \
                 /     |     \
                /      |      \
        Node Exporter  |   Blackbox
           :9100       |      :9115
                       |        |
                       |        +----> 3dots.agency
                       |
                       +----> Alertmanager
                                :9093

