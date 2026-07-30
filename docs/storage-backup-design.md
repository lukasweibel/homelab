# Storage & Backup Design

Status: Grösstenteils umgesetzt (Longhorn, PVC-Migration paperless-ngx/actual-budget, rclone-Raw-Backups, Longhorn-Backup-Target) — siehe TODOs am Ende für den Rest.

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

1. **Longhorn native Backup → Backblaze B2 (Bucket `longhorn-b164-backup`, S3-kompatibel)**
   Block-basiert, inkrementell, läuft direkt aus Longhorn. Für vollständige Disaster-Recovery des gesamten Cluster-/App-Zustands. Nicht menschenlesbar — Restore erfordert einen laufenden Longhorn/k3s.
   Konfiguriert über die `BackupTarget`-CRD `default` (**nicht** über `defaultSettings` im Helm-Chart — die seeden Settings nur beim allerersten Install, wirken auf einer laufenden Instanz nicht rückwirkend), siehe `apps/longhorn-extras/backup-target.yaml`. Credentials als Sealed Secret `longhorn-b2-backup-secret` (Namespace `longhorn-system`).
   Automatischer Zeitplan über `RecurringJob` `daily-backup` (`apps/longhorn-extras/recurringjob-daily-backup.yaml`): täglich 04:00 Uhr, `task: backup`, Retention 7 Generationen. Volumes hängen sich über das Label `recurring-job-group.longhorn.io/daily-backup=enabled` an; beide StorageClasses (`longhorn-replicated`, `longhorn-single`) haben dafür `recurringJobSelector` gesetzt, sodass neue Volumes automatisch gelabelt werden. Bereits bestehende Volumes wurden einmalig manuell gelabelt (Longhorn-`Volume`-Objekte sind Laufzeit-State mit dynamischen Namen, kein GitOps-Ziel).

2. **Rohdateien-Sync via rclone-CronJobs → Backblaze B2 (je App ein eigener Bucket + Application Key)**
   Echte, einzeln abrufbare Dateien, direkt über das B2-Web-Interface (auch vom Handy) einseh- und herunterladbar, ganz ohne Cluster/Longhorn. Ersetzt die ursprünglich angedachte iCloud-Lösung (kein offizieller iCloud-Client für Linux verfügbar / unzuverlässig).
   - **Paperless** (`apps/paperless-raw-backup`): `media/documents/originals/` → Bucket `paperless-raw-backup`. `PAPERLESS_FILENAME_FORMAT` auf `{{ created_year }}/{{ correspondent }}/{{ title }}` gesetzt, damit die Ablage im Bucket durchsuchbar/browsbar bleibt statt flacher IDs.
   - **Actual Budget** (`apps/actualbudget-raw-backup`): kompletter `/data`-Ordner (SQLite-Budgetdatei + Anhänge) → Bucket `actualbudget-raw-backup`.
   Beide laufen als tägliche `CronJob`s (`rclone sync`, Schedule `0 3 * * *`), mounten die jeweilige PVC read-only. Restore ist trivial und unabhängig von k3s: Bucket-Inhalt herunterladen und z.B. `docker run -v ./data:/data actualbudget/actual-server` (bzw. die Original-Dateien direkt öffnen) — kein Kubernetes nötig.
   Versionierung ("Keep All Versions") auf beiden Buckets aktiviert, falls in einer App versehentlich etwas gelöscht/überschrieben wird.

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
- [x] actual-budget PVC von `local-path` auf `longhorn-replicated` migriert (siehe Migrationspfad oben)
- [ ] Verbleibende PVCs (n8n, authentik-db) von `local-path` auf `longhorn-replicated` migrieren
- [x] B2-Bucket (`longhorn-b164-backup`) angelegt, Longhorn-Backup-Target konfiguriert
- [x] Longhorn `RecurringJob` `daily-backup` eingerichtet (täglich 04:00, Retention 7), alle bestehenden Volumes gelabelt, StorageClasses labeln neue Volumes automatisch
- [x] rclone-Cronjob (raw sync) für Paperless-Originale nach B2 (`paperless-raw-backup`, Bucket `paperless-raw-backup`)
- [x] rclone-Cronjob (raw sync) für Actual-Budget-Datei nach B2 (`actualbudget-raw-backup`, Bucket `actualbudget-raw-backup`)
- [ ] Lokale Kopie auf USB-SSD (Ebene 3)
