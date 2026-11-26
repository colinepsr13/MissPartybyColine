# 👑 Miss Party 2027

## 📱 Version web : gratuite, depuis l'iPhone, sans rien installer

Le dossier [`docs/`](docs) contient une **version web** de l'app, avec les mêmes fonctionnalités
(salons, code d'invitation, notes tenue / maquillage / danse / discours, classements, chat).
Elle s'ouvre dans Safari et s'installe sur l'écran d'accueil comme une vraie app.

**Mettre l'app en ligne (une seule fois, depuis l'iPhone)** :
1. Sur github.com, ouvre ce dépôt > **Settings** > **Pages**.
2. *Source* : **Deploy from a branch**. *Branch* : `claude/miss-france-ranking-app-27vy7k`, dossier **`/docs`**, puis **Save**.
3. Une minute plus tard, l'app est en ligne sur **https://colinepsr13.github.io/d-p-t-coline-/**

**L'installer** : ouvre le lien dans Safari > bouton **Partager** ⬆️ > **« Sur l'écran d'accueil »**.

**Inviter les copines** : dans le salon, onglet *Salon* > **Inviter**. Elles reçoivent le lien et le code.

La synchronisation en direct passe par [ntfy.sh](https://ntfy.sh), un service gratuit et sans compte.
Les salons restent disponibles 12 h après leur dernière activité : crée-le le soir de l'élection.
Ce service public limite le nombre d'envois par connexion internet ; l'app regroupe les notes et
réessaie toute seule si besoin (« envoi en attente »).

---

## Version iPhone native (nécessite un Mac)

Application iPhone pour regarder l'élection de **Miss France 2027** entre copines, même à distance,
et noter ensemble vos Miss préférées.

## Fonctionnalités

- **Salons privés** : crée un salon, donne-lui le nom que tu veux (renommable ensuite).
- **Invitation par code** : chaque salon a un code à 6 caractères (ex. `K7PQ2M`) à partager par SMS,
  WhatsApp… via le bouton « Inviter ».
- **Les 31 Miss régionales** déjà dans la liste. L'organisatrice peut ajouter le prénom et le nom
  de chaque candidate, la marquer éliminée et couronner la gagnante.
- **Notation de 1 à 10** sur 4 critères :
  - 👗 Tenue
  - 💄 Maquillage
  - 💃 Danse
  - 🎤 Discours
- **Classements en direct** : classement du groupe ou le tien, général ou par critère, avec les
  « prix du salon » (meilleure tenue, meilleur maquillage, meilleure danse, meilleur discours).
- **Suivi de l'émission** : l'organisatrice indique l'étape en cours (défilés, Top 15, Top 5,
  couronnement…), tout le monde la voit en temps réel.
- **Chat du salon** avec réactions rapides 😍 👑 🔥 😱 pour commenter le show à distance.
- Tout est synchronisé en temps réel entre les téléphones (Firebase).

## Ce qu'il te faut

- Un **Mac** avec **Xcode 16 ou plus récent** (gratuit sur le Mac App Store).
- Un **iPhone sous iOS 17** ou plus récent.
- Un **compte Apple** (le compte gratuit suffit pour installer l'app sur ton propre iPhone).
- Un **compte Google** pour créer le projet Firebase (gratuit).

## Installation pas à pas

### 1. Créer le projet Firebase (la « base de données » partagée)

1. Va sur <https://console.firebase.google.com> et clique sur **Créer un projet** (ex. « miss-party »).
2. Dans **Créer > Authentication**, clique sur **Commencer**, puis active le fournisseur **Anonyme**.
3. Dans **Créer > Firestore Database**, clique sur **Créer une base de données**
   (emplacement `eur3 (europe-west)`, mode **production**).
4. Toujours dans Firestore, onglet **Règles** : remplace tout le contenu par celui du fichier
   [`firestore.rules`](firestore.rules) de ce dépôt, puis **Publier**.
5. Dans **Paramètres du projet** (roue dentée) > **Vos applications**, ajoute une application **iOS** :
   - Identifiant du bundle : `fr.missparty.app` (ou le tien, voir étape 2.3)
   - Télécharge le fichier **`GoogleService-Info.plist`**.

### 2. Lancer l'app sur ton iPhone

1. Télécharge ce dépôt et copie `GoogleService-Info.plist` dans le dossier `MissFranceParty/`
   (à côté des dossiers `App`, `Views`…).
2. Double-clique sur **`MissFranceParty.xcodeproj`**. Xcode télécharge automatiquement Firebase
   (patiente une minute la première fois).
3. Clique sur le projet **MissFranceParty** > onglet **Signing & Capabilities** :
   choisis ton compte Apple dans **Team**. Si Xcode refuse l'identifiant, change le
   **Bundle Identifier** (ex. `fr.coline.missparty`) et mets le même dans Firebase.
4. Branche ton iPhone, sélectionne-le en haut de Xcode, puis clique sur ▶️.
5. Sur l'iPhone : **Réglages > Général > VPN et gestion de l'appareil** → fais confiance à ton compte
   développeur, puis active le **Mode développeur** si demandé.

### 3. Partager l'app avec les copines

- **Le plus simple : TestFlight** (nécessite le programme Apple Developer, 99 €/an) :
  dans Xcode, **Product > Archive** puis **Distribute App > TestFlight**. Tes copines installent
  l'app **TestFlight** et reçoivent ton invitation par e-mail.
- **Gratuit** : branche l'iPhone de chaque copine sur ton Mac et répète l'étape 2.4
  (avec un compte gratuit, l'app doit être réinstallée tous les 7 jours).

## Le soir de l'élection 🎉

1. L'organisatrice crée le salon et appuie sur **Inviter** (onglet *Salon*) pour envoyer le code.
2. Les copines choisissent leur pseudo, puis **Rejoindre avec un code**.
3. Pendant le show, chacune note les Miss dans l'onglet **Candidates** (touche une Miss →
   une note de 1 à 10 par critère ; touche à nouveau la même note pour l'effacer).
4. L'organisatrice fait avancer l'**étape de l'émission**, marque les Miss éliminées
   et couronne la gagnante.
5. Onglet **Classement** : comparez vos classements et découvrez les prix du salon !

## Structure du projet

```
MissFranceParty/
├── App/MissFrancePartyApp.swift     Point d'entrée (initialise Firebase)
├── Models/Models.swift              Salons, candidates, votes, critères, étapes du show
├── Services/
│   ├── SessionStore.swift           Connexion anonyme + pseudo
│   ├── RoomRepository.swift         Créer / rejoindre / quitter un salon (code d'invitation)
│   ├── HomeStore.swift              Liste de mes salons en temps réel
│   └── RoomStore.swift              Données temps réel d'un salon + calcul des classements
├── Views/                           Écrans SwiftUI (accueil, candidates, notation, classement, chat, salon)
└── Resources/Assets.xcassets        Couleurs et icône
firestore.rules                      Règles de sécurité Firebase
project.yml                          Config XcodeGen (optionnel, pour régénérer le projet)
```

### Données Firestore

```
rooms/{roomId}                 name, code, hostId, memberIds, phase, createdAt
  members/{userId}             name, joinedAt
  candidates/{c01…c30}         number, region, name, eliminated, crowned
  votes/{userId_candidateId}   userId, candidateId, scores { tenue, maquillage, danse, discours }
  messages/{id}                userId, userName, text, createdAt
```

## Personnaliser

- **Icône de l'app** : glisse une image 1024×1024 dans `Resources/Assets.xcassets/AppIcon`.
- **Critères** : modifie l'énumération `Criterion` dans `Models/Models.swift`
  (ajoute par exemple `case maillot` ou `case culture`) — tout le reste s'adapte automatiquement.
- **Régions** : la liste `CandidateCatalog.regions` dans le même fichier.
