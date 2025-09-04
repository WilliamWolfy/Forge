# 📘 Documentation — `forge-bootstrap.sh`

## 🔧 Rôle

`forge-bootstrap.sh` est le script d’initialisation d’un projet **Forge**.
Il crée l’arborescence de base, installe les fichiers nécessaires (README, script principal, config, etc.), et configure l’environnement minimal pour travailler.

Il est pensé pour être :

* **multi-plateforme** (Linux, macOS, Windows via Git Bash)
* **extensible** (via hooks et templates)
* **sécurisé** (jamais d’écrasement sans `--update`)
* **dynamique** (le projet généré n’est pas limité à `forge`, tu peux nommer comme tu veux).

---

## ⚙️ Options disponibles

```bash
./forge-bootstrap.sh [options] [project-name]
```

### 📌 Options

* `--local` → force l’utilisation des fichiers locaux (templates internes).
* `--remote` → force le téléchargement depuis un dépôt distant.
* `--auto` → tente le mode remote, sinon fallback local (valeur par défaut).
* `--update` → met à jour les fichiers existants (sans ça, rien n’est écrasé).
* `--help, -h, help, ?` → affiche l’aide intégrée.

### 📌 Arguments

* `[project-name]` → nom de ton projet.

  * Sert à nommer le dossier (`my-app/`)
  * Sert à nommer le script principal (`my-app.sh`).

---

## 📂 Arborescence générée

Un appel basique produit :

```
my-app/
 ├─ README.md
 ├─ my-app.sh          # script principal, alias du projet
 ├─ core/
 │   └─ system.sh      # utilitaires système (détection OS, etc.)
 ├─ lang/
 │   ├─ en.json
 │   └─ fr.json
 ├─ modules/
 │   └─ .keep
 ├─ templates/
 │   └─ .keep
 ├─ hooks/
 │   ├─ pre-bootstrap.sh   (optionnel)
 │   └─ post-bootstrap.sh  (optionnel)
 └─ .gitignore
```

---

## 🧩 Fonctionnalités clés

### 1️⃣ **Nom dynamique**

Le script principal prend toujours le **nom du projet**.
Exemple :

```bash
./forge-bootstrap.sh my-app
```

👉 Résultat : fichier généré = `my-app.sh`

---

### 2️⃣ **Modes d’installation**

* **Local** → basé sur les templates fournis par le bootstrap.
* **Remote** → télécharge depuis `https://example.com/<project-name>/...` (personnalisable).
* **Auto** (par défaut) → essaie remote, sinon bascule en local.

Exemple :

```bash
./forge-bootstrap.sh my-app --remote
```

👉 Tente un fetch distant (`README.md`, `system.sh`, etc.).

---

### 3️⃣ **Protection des fichiers**

* Si un fichier existe déjà, il **n’est jamais écrasé** (sauf `--update`).
* Exemple :

```bash
./forge-bootstrap.sh my-app
# Génère README.md
./forge-bootstrap.sh my-app
# "ℹ️ Skipping existing: README.md"
./forge-bootstrap.sh my-app --update
# Écrase README.md
```

---

### 4️⃣ **Hooks (extensibilité)**

Le dossier `hooks/` permet de lancer des scripts **avant/après bootstrap** :

* `hooks/pre-bootstrap.sh` → exécuté juste avant la génération.
* `hooks/post-bootstrap.sh` → exécuté après la génération.

Exemple :

```bash
# hooks/pre-bootstrap.sh
#!/usr/bin/env bash
echo "🔗 Préparation du projet $1..."
```

👉 Chaque hook reçoit en arguments :
`$1 = project_name`
`$2 = mode`
`$3 = update_flag`

---

### 5️⃣ **Détection OS intégrée**

`core/system.sh` fournit une fonction réutilisable :

```bash
detect_platform
```

Retourne :

* `linux`
* `macos`
* `windows`
* `unknown`

Exemple d’usage :

```bash
PLATFORM=$(detect_platform)
echo "Plateforme détectée : $PLATFORM"
```

---

### 6️⃣ **Alias automatique**

Si un script `forge-alias.sh` (windows: forge-alias.ps1) existe à la racine, il est exécuté à la fin du bootstrap.
Son rôle est de créer un **alias shell** pour lancer le projet directement par son nom.

Exemple attendu après `alias.sh` :

```bash
$ my-app help
Usage: my-app <command> [args]
```

---

## 🚀 Exemples concrets

### Créer un projet simple

```bash
./forge-bootstrap.sh my-app
```

👉 Produit `my-app.sh` avec tous les fichiers par défaut.

---

### Forcer le mode local

```bash
./forge-bootstrap.sh my-app --local
```

👉 Ignore le remote, utilise uniquement les templates inclus.

---

### Mettre à jour un projet existant

```bash
./forge-bootstrap.sh my-app --update
```

👉 Réécrit les fichiers avec les nouvelles versions des templates.

---

### Utiliser un hook de personnalisation

```bash
mkdir -p my-app/hooks
echo '#!/usr/bin/env bash' > my-app/hooks/post-bootstrap.sh
echo 'echo "✨ Mon hook post-install exécuté pour $1"' >> my-app/hooks/post-bootstrap.sh
chmod +x my-app/hooks/post-bootstrap.sh

./forge-bootstrap.sh my-app
```

👉 Affichera `✨ Mon hook post-install exécuté pour my-app`.


👉 Oui, le script est déjà capable d’utiliser un **template distant** (via `REMOTE_BASE`).
S’il échoue → fallback sur le **template local** (déjà inclus).
Et si tu ajoutes un vrai repo distant (`https://example.com/...`) tu peux remplacer tous les fichiers par une version partagée.
