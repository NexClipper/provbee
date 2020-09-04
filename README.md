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
    
 default install : curl -sL http://gg.gg/provbee | K3S_SET=N K_API_KEY="zzzxxx" K_PLATFORM="kubernetes" K_MANAGER_URL="http://console.nexclipper.io:8090" K_ZONE_ID="NUM" bash

## 간단한 설명
* 설치 스크립트로 설치시 kubernetes가 기본으로 사용중으로 가정하고 진행.(osx,linux 구분 없음)
* namespace, serviceaccount 등을 생성하며, provbee가 사용할 kebe-config 파일도 자동 생성
* provbee와 klevr-agent는 ssh로 연결되어 있으며, klevr-agent가 klevr-server로 부터 task를 받아 provbee에게 요청

## terraform & kubectl & helm command 

## terraform officer provider add command
### ex:) /provider.sh aws 3.2.1
