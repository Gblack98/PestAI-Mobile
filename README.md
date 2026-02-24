# 📱 PestAI Mobile

Application Flutter pour la détection agronomique par IA, connectée à l'API **PestAI** (AbiHack 2025).

---

## 📸 Fonctionnalités

- Prise de photo via **caméra** ou import depuis la **galerie**
- 3 types d'analyse : **Plante/Ravageur**, **Satellite**, **Drone**
- Affichage des détections avec **niveau de sévérité** coloré
- Visualisation des **zones découpées** (crops Cloudinary)
- Recommandations détaillées : biologiques, chimiques, culturales
- Support **thème clair / sombre**

---

## 🗂️ Structure

```
lib/
├── main.dart                  # Point d'entrée
├── config.dart                # URL de l'API
├── models.dart                # Modèles de données
├── services/
│   └── api_service.dart       # Appels HTTP à l'API PestAI
├── screens/
│   ├── home_screen.dart       # Écran principal (sélection image + type)
│   └── result_screen.dart     # Affichage des résultats
└── widgets/
    ├── detection_card.dart    # Carte pour chaque détection
    └── severity_badge.dart    # Badge coloré (LOW/MEDIUM/HIGH/CRITICAL)
```

---

## ⚙️ Installation

### Prérequis
- [Flutter SDK](https://docs.flutter.dev/get-started/install) ≥ 3.0
- Android Studio ou VS Code avec l'extension Flutter
- Un émulateur Android ou un téléphone physique

### Étapes

```bash
# 1. Cloner le repo
git clone https://github.com/Gblack98/PestAI-Mobile.git
cd PestAI-Mobile

# 2. Installer les dépendances
flutter pub get

# 3. Configurer l'URL de l'API
# Éditer lib/config.dart et remplacer kApiBaseUrl par ton URL Railway
```

### Lancer l'app

```bash
flutter run
```

### Générer l'APK

```bash
flutter build apk --release
# APK disponible dans : build/app/outputs/flutter-apk/app-release.apk
```

---

## 🔧 Configuration

Dans `lib/config.dart`, remplace l'URL par celle de ton déploiement Railway :

```dart
const String kApiBaseUrl = 'https://ton-projet.railway.app';
```

---

## 🔑 Permissions Android

Les permissions suivantes sont déclarées dans `AndroidManifest.xml` :
- `INTERNET` — appels API
- `CAMERA` — prise de photo
- `READ_MEDIA_IMAGES` / `READ_EXTERNAL_STORAGE` — accès galerie

---

## 📦 Dépendances

| Package | Version | Rôle |
|---|---|---|
| `http` | ^1.2.0 | Requêtes HTTP multipart |
| `image_picker` | ^1.1.2 | Caméra et galerie |
| `cached_network_image` | ^3.3.1 | Affichage images Cloudinary |

---

## 🔗 API

L'app utilise l'endpoint `POST /api/v12/analyze` de [PestAI API](https://github.com/Gblack98/AbiHack2025_PestAI).

---

## 👤 Auteur

**Gblack98** — [github.com/Gblack98](https://github.com/Gblack98)
