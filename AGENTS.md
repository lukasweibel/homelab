# Hinweise für Agents in diesem Repo

Dieses Repo ist die einzige Quelle der Wahrheit für den Cluster-Zustand (GitOps via ArgoCD, `automated: {prune: true, selfHeal: true}` auf praktisch allen Apps).

## Grundregel

**Jede gewollte Zustandsänderung geht über einen Commit, nicht über `kubectl` direkt am Cluster.**

- Skalieren, Config-Werte, StorageClass, Ressourcen-Limits etc. → in der jeweiligen `values.yaml` / dem Manifest ändern, committen, pushen. Nicht `kubectl scale`, `kubectl edit`, `kubectl patch` auf Deployment/Application-Spec-Felder.
- Grund: `selfHeal` macht jede imperative Änderung innert Sekunden bis Minuten rückgängig — und kann dabei Nebeneffekte auslösen (z.B. leere PVCs neu anlegen, wenn ein Deployment wieder hochskaliert wird, während die alte PVC gerade gelöscht wurde).
- Auch scheinbar "temporäre" Operationen (App kurz stoppen für eine Migration) über einen Commit machen (z.B. `replicaCount: 0`), nicht über `kubectl scale` — sonst kämpft man dauerhaft gegen ArgoCD.

## Was trotzdem imperativ per `kubectl` laufen darf

- Rein lesende Befehle (`get`, `describe`, `logs`) zur Diagnose.
- Echte Einweg-Vorgänge, die nicht Teil des gewünschten Endzustands sind: Helper-Pods für Datenmigration, temporäre PVCs, die danach wieder verschwinden, `claimRef` auf einem PV leeren, um es neu zu binden.
- Der **resultierende Endzustand** (z.B. eine PVC, die dauerhaft existieren soll) muss aber wieder im Repo landen — z.B. über ein optionales `volumeName`-Feld im Helm-Chart, das explizit auf ein bestehendes PV zeigt, statt die PVC per `kubectl apply` am Repo vorbei anzulegen.

## ArgoCD-Debugging-Fallstricke

- Ein Application-Status kann veraltet/irreführend sein, wenn das Objekt in `Terminating` hängt (z.B. wegen eines fehlschlagenden `pre-delete`-Hooks). Vor dem Vertrauen auf `.status` immer `metadata.deletionTimestamp` und `metadata.finalizers` prüfen.
- Helm-Charts mit `pre-upgrade`/`pre-delete`-Hooks können bei einem Fresh-Install/durch ArgoCDs Hook-Handling unerwartet fehlschlagen (z.B. referenzierte ServiceAccount existiert noch nicht). Nicht blind Werte raten — im Chart-Source nachschauen, welche `.Values`-Flags die Hook-Jobs wirklich gaten.
- Bei API-Version-Fehlern (`could not find version X, version Y is installed`) die tatsächlich servierte CRD-Version direkt prüfen (`kubectl get crd <name> -o jsonpath='{.spec.versions[*].name}'`), statt der Fehlermeldung blind zu glauben — sie kann während eines laufenden Migrations-/Reset-Vorgangs stale sein.

## Secrets-Workflow

Ich (Claude) sehe nie Klartext-Credentials — Secrets erstellt der User selbst mit seinem eigenen Seal-Script.

1. Ich gebe den exakten Ziel-Dateinamen (`clusters/home-cluster/secrets/<name>.yaml`) plus ein unsealed-Secret-Template zum Reinkopieren, mit allen nötigen Keys und Platzhaltern, z.B.:
   ```yaml
   apiVersion: v1
   kind: Secret
   metadata:
     name: paperless-raw-backup-secrets
     namespace: paperless-ngx
   type: Opaque
   stringData:
     RCLONE_CONFIG_B2_TYPE: b2
     RCLONE_CONFIG_B2_ACCOUNT: "account"
     RCLONE_CONFIG_B2_KEY: "key"
   ```
   Das Template direkt als Text im Chat ausgeben (nicht nur als Datei-Pfad referenzieren) — der User legt es selbst an, füllt die Werte aus und sealed es mit seinem eigenen Script.
2. User legt die gesealte Datei unter `clusters/home-cluster/secrets/<name>.yaml` ab.
3. Ich prüfe nur noch die Struktur der gesealten Datei (Name/Namespace/Keys stimmen mit dem Template überein) und trage den Dateinamen in `clusters/home-cluster/secrets/kustomization.yaml` ein.

## Dokumentation

Docs (`docs/*.md`) hoch-level halten, nicht als tiefes Schritt-für-Schritt-Runbook — Details stehen im Code/den Manifesten selbst.
