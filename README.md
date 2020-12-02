# ProvBee
![ProvBee_logo.png](https://github.com/NexClipper/provbee/raw/master/assets/ProvBee_logo.png)

```
                                                                                        
88888888ba                                         88888888ba                           
88      "8b                                        88      "8b                          
88      ,8P                                        88      ,8P                          
88aaaaaa8P'  8b,dPPYba,   ,adPPYba,   8b       d8  88aaaaaa8P'   ,adPPYba,   ,adPPYba,  
88""""""'    88P'   "Y8  a8"     "8a  `8b     d8'  88""""""8b,  a8P_____88  a8P_____88  
88           88          8b       d8   `8b   d8'   88      `8b  8PP"""""""  8PP"""""""  
88           88          "8a,   ,a8"    `8b,d8'    88      a8P  "8b,   ,aa  "8b,   ,aa  
88           88           `"YbbdP"'       "8"      88888888P"    `"Ybbd8"'   `"Ybbd8"'  
                                                                                        
```

## Property map and positions
![Property_map_overview.png](https://github.com/NexClipper/provbee/raw/master/assets/Property_map_overview.png)

## ProvBee position
[![NexClipper_work_process_flows.png](https://raw.githubusercontent.com/NexClipper/provbee/master/assets/NexClipper_work_process_flows.png)](https://www.youtube.com/watch?v=yg-TvT8-qw8)

## Interconnector
provbee 단독 실행시 kubectl, terraform, helm 등의 명령어셋을 가짐

klevr-agent와 연결 시 klevr를 통해 task 등을 전달 받아 job을 실행

### He is workman.  
* Kubernetes Role, Namespace, ServiceAccount and etc create.(for NexClipper)  
* Provbee, Klevr-Agent container include  
* If you want, I will install K3s as well.  

## Features
* **Install script** (with [nexclipper console](http://console.nexclipper.io))    
   * ex) curl -sL http://gg.gg/provbee | K3S_SET=N K_API_KEY="zzzxxx" K_PLATFORM="kubernetes" K_MANAGER_URL="http://console.nexclipper.io:8090" K_ZONE_ID="NUM" bash
   * kubernetes cluster와 기본적으로 연결되어 console에서 사용하는 것을 권장
   * provbee가 사용할 kube-config 를 생성하고, namespace, serviceaccount 도 설정됨 (osx,linux 구분 없음)
   * provbee와 klevr-agent가 ssh키를 공유함
   * klevr-agent를 통해 job을 대기하며, prometheus-operator 이외 task를 통해 설치 가능

## terraform officer provider add command
### ex:) tfprovider aws 3.2.1

## promtool 
* Promtool :[https://prometheus.io/docs/prometheus/latest/configuration/unit_testing_rules/](https://prometheus.io/docs/prometheus/latest/configuration/unit_testing_rules/)
* Unit testing for Prometheus, Alertmanager rules

## Directories and files
```
.
├── Dockerfile                  // docker image build
├── README.md                   // readme 
├── assets                      // readme images
│   └── [Images & Contents]
├── docker-compose.yml          // only provbee docker-compose.yml
├── entrypoint.sh               // docker image build entrypoint
├── install                     // provbee & klevr-agent installer
│   └── provbee.sh
└── scripts                     // docker image build scripts
    ├── get_pubkey.sh           // klevr-agent's authkey script
    ├── provbeecmd.sh           // k8s nodeIP search, provbee ssh status for klevr-agent
    └── provider.sh             // terraform provider already download
```
## Install TEST
[![asciicast](https://asciinema.org/a/frQ5bTQIysMf4D2igQaT2vHME.svg)](https://asciinema.org/a/frQ5bTQIysMf4D2igQaT2vHME)
