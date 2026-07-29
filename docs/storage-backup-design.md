# Storage & Backup Design

Status: Entwurf / noch nicht umgesetzt. Dient als Referenz für die Umsetzung, sobald der zweite k3s-Node (rpi-03) dazukommt.

## Ausgangslage

- rpi-01: reiner Docker-Host (AdGuard), **nicht** Teil des k3s-Clusters, für Longhorn irrelevant.
- rpi-02 (`main-node`): k3s-Server/Master, eigene NVMe (2TB). PVCs laufen aktuell über den k3s-Default (`local-path-provisioner`, hostPath auf dem jeweiligen Node). Kein Backup vorhanden.
- rpi-03: neuer k3s-Worker, eigene NVMe (250GB).

Ziel: Storage & Apps sollen node-ausfallsicher sein — fällt ein Node aus, läuft der Rest ohne manuellen Eingriff weiter. Alles soll möglichst in k3s leben (kein separater NFS-Server als Single Point of Failure).

## Storage: Longhorn

Longhorn als CSI-Storage-Provider ersetzt `local-path-provisioner`. Repliziert Volumes über mehrere Nodes; fällt ein Node aus, übernimmt die Replika auf dem anderen Node automatisch.

Zwei StorageClasses für unterschiedliche Datentypen:

| StorageClass | numberOfReplicas | Verwendung |
|---|---|---|
| `longhorn-replicated` | 2 | Kritische, kleine Daten: Paperless-DB, Actual Budget, n8n, Authentik-Postgres |
| `longhorn-single` | 1 | Grosse, unkritische Daten (z.B. Mediathek/Filme) |

Hinweis zur Kapazität: Bei Replica-Count 2 ist die effektiv nutzbare "HA-Kapazität" durch den kleineren Node (rpi-03, 250GB) gedeckelt, nicht durch die Summe (2.25TB). `longhorn-single` kann per Disk-/Node-Tag gezielt auf `main-node` (2TB) gepinnt werden, um dessen volle Kapazität für unreplizierte Daten zu nutzen.

rpi-01 ist nicht Teil des k3s-Clusters und bleibt reiner Docker-Host — kein Thema für Longhorn/Control-Plane-Quorum. Mit nur einem Server-Node (`main-node`) gibt's kein automatisches Control-Plane-Failover, das wird bewusst in Kauf genommen.

## Backup-Ebenen (3-2-1-Prinzip)

1. **Longhorn native Backup → Backblaze B2 (Bucket `homelab-longhorn-backup`)**
   Block-basiert, inkrementell, läuft direkt aus Longhorn. Für vollständige Disaster-Recovery des gesamten Cluster-/App-Zustands. Nicht menschenlesbar — Restore erfordert einen laufenden Longhorn/k3s.

2. **Rohdateien-Sync via rclone → Backblaze B2 (Bucket `homelab-raw-archive`)**
   Echte, einzeln abrufbare Dateien:
   - Paperless: `media/documents/originals/`
   - Actual Budget: Budget-Datei
   Direkt über das B2-Web-Interface (auch vom Handy) einseh- und herunterladbar, ganz ohne Cluster/Longhorn. Ersetzt die ursprünglich angedachte iCloud-Lösung (kein offizieller iCloud-Client für Linux verfügbar / unzuverlässig).
   Cadence: täglich (Deltas sind klein).
   Optional: Versionierung auf dem Bucket aktivieren, falls in Paperless versehentlich etwas gelöscht/überschrieben wird.

3. **Lokale Kopie auf USB-SSD (am Storage-Node)**
   Gleicher Rohdateien-Satz wie Ebene 2, zusätzlich lokal auf einer USB-SSD (kein einfacher Flash-Stick — Schreibzyklen-Verschleiss). Schneller Zugriff ohne Internet-Abhängigkeit bei kleineren Störungen (versehentliches Löschen, kaputtes Upgrade). Schützt **nicht** vor Totalverlust des Standorts (Brand, Diebstahl) — dafür ist B2 da.

Damit: 3 Kopien (Longhorn/NVMe, USB-SSD, B2), 2 Medien (NVMe + USB), 1 offsite (B2).

## PVC-Migrationspfad (local-path → longhorn-replicated)

Am Beispiel paperless-ngx erprobt, gilt als Vorlage für actual-budget, n8n, authentik-db:

1. App in **Git** auf `replicaCount: 0` setzen (nicht per `kubectl scale`!) — sonst holt ArgoCDs `selfHeal` die App innert Sekunden bis Minuten zurück und lässt bei Bedarf sogar neue, leere PVCs entstehen, weil das alte Deployment/StorageClass ja noch im Repo steht. Das kostete uns bei paperless-ngx eine Runde Datenverlust-Schreck (zum Glück nur Testdaten).
2. Neue PVCs auf `longhorn-replicated` anlegen, per Helper-Pod (`rsync`) die Daten von alt (local-path) nach neu kopieren, Dateizahl/-grösse gegenchecken.
3. Alte PVCs löschen; neue (temporäre) PVCs ebenfalls löschen — dank `reclaimPolicy: Retain` bleibt das darunterliegende Longhorn-PV als `Released` erhalten.
4. `claimRef` auf dem retained PV leeren → PV wird wieder `Available`.
5. **Im Chart** (nicht imperativ!) ein optionales `volumeName` pro PVC-Eintrag ergänzen (siehe `paperless-ngx/templates/pvc.yaml` + `values.yaml`), das explizit auf das jeweilige retained PV zeigt. ArgoCD legt die finalen PVCs damit selbst an, GitOps bleibt Source of Truth — kein manuelles `kubectl apply` für Endzustände.
6. `replicaCount` in Git zurück auf 1, App verifizieren.

Ergebnis: Pod kann danach auf jedem Node hochkommen (bestätigt: paperless-ngx lief nach Migration auf `rpi-3` statt `main-node`), da die Daten dank Replikation auf beiden Nodes liegen.

## Offene TODOs

- [x] Longhorn-Deployment + StorageClasses ins Repo (`clusters/home-cluster/argocd/apps/longhorn`, `clusters/home-cluster/apps/longhorn-extras`). Node-Tag `big-disk` auf `main-node` per Longhorn-`Node`-CR gesetzt, damit `longhorn-single` gezielt dorthin pinnt.
- [x] paperless-ngx PVCs von `local-path` auf `longhorn-replicated` migriert (siehe Migrationspfad oben)
- [ ] Verbleibende PVCs (actual-budget, n8n, authentik-db) von `local-path` auf `longhorn-replicated` migrieren
- [ ] B2-Buckets anlegen, Longhorn-Backup-Target konfigurieren
- [ ] rclone-Cronjob (raw sync) für Paperless-Originale + Actual-Budget-Datei nach B2 + USB-SSD
