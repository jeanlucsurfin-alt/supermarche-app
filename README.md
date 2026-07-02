# Fafoutt Store — Guide de démarrage

## Ce qui est déjà fait (Module 1 : POS)
- Écran de vente avec grille de produits + recherche
- Scanner de code-barres (caméra)
- Panier avec quantités modifiables
- Paiement (cash / carte / mobile money) avec calcul de monnaie
- Génération de reçu PDF partageable
- Base de données locale SQLite (fonctionne hors-ligne)

## Comment obtenir votre fichier APK (sans installer Android Studio)

### Étape 1 — Créer un compte GitHub
Allez sur https://github.com et créez un compte gratuit si vous n'en avez pas.

### Étape 2 — Créer un nouveau dépôt (repository)
1. Cliquez sur "New repository"
2. Nommez-le par exemple `supermarche-app`
3. Laissez-le en "Public" ou "Private", cliquez sur "Create repository"

### Étape 3 — Envoyer le code sur GitHub
Sur votre ordinateur, dans le dossier `supermarche_app` :
```bash
git init
git add .
git commit -m "Version initiale - Module POS"
git branch -M main
git remote add origin https://github.com/VOTRE-NOM/supermarche-app.git
git push -u origin main
```

### Étape 4 — Récupérer l'APK
1. Sur GitHub, allez dans l'onglet **Actions** de votre dépôt
2. Vous verrez le workflow "Build APK" en train de tourner (2-3 minutes)
3. Une fois terminé (coche verte ✅), cliquez dessus
4. En bas de la page, téléchargez l'artefact **supermarche-apk** (fichier .zip contenant l'APK)
5. Décompressez et installez `app-release.apk` sur votre téléphone Android

*Note : Android bloquera l'installation par défaut ("source inconnue") — acceptez dans les paramètres de sécurité pour installer.*

## Prochains modules à développer
- Gestion des stocks (entrées/sorties, alertes)
- Gestion des produits (ajout/modification/suppression avec photos)
- Gestion des employés (rôles, connexion par PIN)
- Rapports de ventes et bénéfices
- Mode synchronisation cloud

Dites-moi quand vous voulez qu'on ajoute le prochain module.
