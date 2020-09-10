# ProvBee
![ProvBee_logo.png](https://github.com/NexClipper/provbee/raw/master/assets/ProvBee_logo.png)

## Property map and positions
![Property_map_overview.png](https://github.com/NexClipper/provbee/raw/master/assets/Property_map_overview.png)

## ProvBee position
[![NexClipper_work_process_flows.png](https://raw.githubusercontent.com/NexClipper/provbee/master/assets/NexClipper_work_process_flows.png)](https://www.youtube.com/watch?v=yg-TvT8-qw8)

### He is workman.  
* Kubernetes Role, Namespace, ServiceAccount and etc create.(for NexClipper)  
* Provbee, Klevr-Agent container include  
* If you want, I will install K3s as well.  
<<<<<<< HEAD
=======
    
 default install : curl -sL http://gg.gg/provbee | K3S_SET=N K_API_KEY="zzzxxx" K_PLATFORM="kubernetes" K_MANAGER_URL="http://console.nexclipper.io:8090" K_ZONE_ID="NUM" bash

## 간단한 설명
* 설치 스크립트로 설치시 kubernetes가 기본으로 사용중으로 가정하고 진행.(osx,linux 구분 없음)
* namespace, serviceaccount 등을 생성하며, provbee가 사용할 kebe-config 파일도 자동 생성
* provbee와 klevr-agent는 ssh로 연결되어 있으며, klevr-agent가 klevr-server로 부터 task를 받아 provbee에게 요청
>>>>>>> 662f8dfb72fb1bfdbfabb8aa7c1a2f86ea77797f

## Interconnector
provbee 단독 실행시 kubectl, terraform, helm 등의 명령어셋을 가짐

klevr-agent와 연결 시 klevr를 통해 task 등을 전달 받아 job을 실행

## Features
* **Install script** (with [nexclipper console](https://github.com/NexClipper/nexclipper-server))    
* ex) curl -sL http://gg.gg/provbee | K3S_SET=N K_API_KEY="zzzxxx" K_PLATFORM="kubernetes" K_MANAGER_URL="http://console.nexclipper.io:8090" K_ZONE_ID="NUM" bash
* kubernetes cluster와 기본적으로 연결되어 console에서 사용하는 것을 권장
* provbee가 사용할 kube-config 를 생성하고, namespace, serviceaccount 도 설정됨 (osx,linux 구분 없음)
* provbee와 klevr-agent가 ssh키를 공유하며, 처음 구동시 기본 task를 실행하게 됨
* 첫번째 task : prometheus-operator 를 배포
* 추후 klevr-agent를 통해 job을 대기

## terraform officer provider add command
### ex:) tfprovider aws 3.2.1

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