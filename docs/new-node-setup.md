# Neue Node einrichten

Status: In Arbeit. Dokumentiert die Schritte zum Hinzufügen einer neuen k3s-Node
(NVMe, 256GB) zum bestehenden Cluster, als Vorbereitung für Longhorn
(siehe [storage-backup-design.md](./storage-backup-design.md)).

Reihenfolge: **Node zuerst fertig einrichten und dem Cluster beitreten lassen,
danach Longhorn installieren** — Longhorn bringt erst mit ≥2 Nodes echten
Nutzen (Replikation).

## 1. Betriebssystem ✅

Raspberry Pi OS Lite (64-bit) — identisch zur bestehenden Node (Debian 13
"trixie", aarch64). Geflasht per Raspberry Pi Imager.

## 2. NVMe einrichten ✅

Von SD-Karte booten, PCIe/NVMe aktivieren, System per `rpi-clone` von SD auf
die NVMe-SSD klonen, Boot-Reihenfolge auf NVMe zuerst umstellen, SD-Karte
entfernen und Boot von NVMe verifizieren.

- [x] Erledigt

## 3. Netzwerk / IP ✅

Node bootete zunächst ganz ohne feste IP (normale DHCP-Adresse) — darüber
wurde gebootstrapped/deployt. Feste IP danach per Static-DHCP-Reservierung
im WLAN-Router (per MAC-Adresse) vergeben. Kein statisches Netzwerk-Setup
auf der Node selbst (Lehre aus rpi-01, wo eine feste IP lokal &
undokumentiert am Gerät gesetzt wurde, statt im Repo/Router
nachvollziehbar).

- [x] Erledigt

## 4. Node-Konfiguration im Repo ✅

`infrastructure/hosts/rpi-03/host.yaml` angelegt (analog zu `rpi-02`), inkl.
`open-iscsi` als Package (Voraussetzung für Longhorn) und passendem
Workflow-Job (`apply-rpi-03`) in `manage-host.yaml`. Kein `docker` als
Service — rpi-03 ist reiner k3s-Worker, kein Docker-Host.

- [x] Erledigt

## 5. k3s-Beitritt ✅

Node dem bestehenden k3s-Cluster (Server: `main-node`) per offiziellem
Install-Script (`get.k3s.io`) als Agent hinzugefügt, `Ready`-Status
bestätigt. Node erscheint im Cluster als `rpi-3` (Hostname), nicht `rpi-03`
— bewusst so belassen.

Pi-spezifischer Gotcha: `k3s-agent` startet ohne aktiviertes `memory`-Cgroup
nicht (auf Raspberry Pi OS nicht standardmässig an) — `cgroup_memory=1
cgroup_enable=memory` an `/boot/firmware/cmdline.txt` anhängen und rebooten.

- [x] Erledigt

## 6. Longhorn (danach, separater Schritt)

Als ArgoCD-Application (`longhorn`) installiert, StorageClasses
`longhorn-replicated` (2 Replicas) und `longhorn-single` (1 Replica,
gepinnt auf `main-node` per Node-Tag `big-disk`) + Ingress + Homepage-Eintrag
in `longhorn-extras` gemäss [storage-backup-design.md](./storage-backup-design.md)
angelegt. Noch offen: `open-iscsi` auf allen Nodes verifizieren, PVCs
migrieren.

- [ ] Erledigt
