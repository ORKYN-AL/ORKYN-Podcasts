import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:html' as html;
import 'dart:convert';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyD0sExmKe5-NTzfdW-dAnmGvB9kGQWp8rE",
      authDomain: "al-podcasts.firebaseapp.com",
      projectId: "al-podcasts",
      storageBucket: "al-podcasts.firebasestorage.app",
      messagingSenderId: "1084059668245",
      appId: "1:1084059668245:web:22025c16163513148ae31c",
    ),
  );
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  ThemeMode _themeMode = ThemeMode.light;
  bool _isAlreadyAuthenticated = false;

  @override
  void initState() {
    super.initState();
    _isAlreadyAuthenticated = html.window.localStorage['orkyn_auth'] == 'true';
    
    final String? themeSauvegarde = html.window.localStorage['theme_mode'];
    if (themeSauvegarde == 'dark') {
      _themeMode = ThemeMode.dark;
    } else {
      _themeMode = ThemeMode.light;
    }
  }

  void _changerTheme(bool passerEnSombre) {
    setState(() {
      _themeMode = passerEnSombre ? ThemeMode.dark : ThemeMode.light;
      html.window.localStorage['theme_mode'] = passerEnSombre ? 'dark' : 'light';
    });
  }

  void _validerConnexion(bool connecte) {
    setState(() {
      _isAlreadyAuthenticated = connecte;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      themeMode: _themeMode,
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Segoe UI',
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFF4F7F9),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Segoe UI',
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF121212), 
      ),
      home: _isAlreadyAuthenticated
          ? PodcastScreen(
              isDarkMode: _themeMode == ThemeMode.dark,
              onThemeChanged: _changerTheme,
              onLogout: () {
                html.window.localStorage.remove('orkyn_auth');
                _validerConnexion(false);
              },
            )
          : AuthScreen(
              isDarkMode: _themeMode == ThemeMode.dark,
              onThemeChanged: _changerTheme,
              onLoginSuccess: () => _validerConnexion(true),
            ),
    );
  }
}

class AuthScreen extends StatefulWidget {
  final bool isDarkMode;
  final Function(bool) onThemeChanged;
  final VoidCallback onLoginSuccess;
  
  const AuthScreen({
    super.key, 
    required this.isDarkMode, 
    required this.onThemeChanged,
    required this.onLoginSuccess
  });

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String _message = "";
  final String _motDePasseSecretOrkyn = "Orkyn2026!"; 

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _connexion() {
    final email = _emailController.text.trim().toLowerCase();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      setState(() { _message = "Veuillez remplir tous les champs."; });
      return;
    }

    if (!email.endsWith('@orkyn.fr') && !email.endsWith('@airliquide.com')) {
      setState(() { _message = "Accès refusé : adresse @orkyn.fr ou @airliquide.com requise."; });
      return;
    }

    if (password == _motDePasseSecretOrkyn) {
      html.window.localStorage['orkyn_auth'] = 'true';
      if (html.window.localStorage['last_check'] == null) {
        html.window.localStorage['last_check'] = DateTime.now().toIso8601String();
      }
      widget.onLoginSuccess();
    } else {
      setState(() { _message = "Mot de passe d'entreprise incorrect."; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color cardColor = widget.isDarkMode ? const Color(0xFF1E1E1E) : Colors.white;
    final Color textColor = widget.isDarkMode ? Colors.white : const Color(0xFF0F172A);

    return Scaffold(
      body: Stack(
        children: [
          Positioned(
            top: 16,
            right: 16,
            child: IconButton(
              icon: Icon(
                widget.isDarkMode ? Icons.wb_sunny_rounded : Icons.nightlight_round,
                color: widget.isDarkMode ? Colors.amber : const Color(0xFF475569),
              ),
              onPressed: () => widget.onThemeChanged(!widget.isDarkMode),
            ),
          ),
          Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 400),
              padding: const EdgeInsets.all(32.0),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 20, offset: const Offset(0, 8))],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text("Connexion Pro", textAlign: TextAlign.center, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: textColor)),
                  const SizedBox(height: 8),
                  const Text("Réservé aux collaborateurs ORKYN' & AIR LIQUIDE", textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: Color(0xFF0EA5E9), fontWeight: FontWeight.w500)),
                  const SizedBox(height: 24),
                  if (_message.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                      child: Text(_message, style: const TextStyle(color: Colors.red, fontSize: 13, fontWeight: FontWeight.w500)),
                    ),
                    const SizedBox(height: 16),
                  ],
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    style: TextStyle(color: widget.isDarkMode ? Colors.white : Colors.black),
                    decoration: InputDecoration(
                      labelText: "Votre e-mail pro",
                      hintText: "prenom.nom@orkyn.fr",
                      prefixIcon: const Icon(Icons.email_rounded),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _passwordController,
                    obscureText: true,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _connexion(),
                    style: TextStyle(color: widget.isDarkMode ? Colors.white : Colors.black),
                    decoration: InputDecoration(
                      labelText: "Mot de passe de l'application",
                      prefixIcon: const Icon(Icons.lock_rounded),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _connexion,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFA855F7),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text("Se connecter", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class PodcastScreen extends StatefulWidget {
  final bool isDarkMode;
  final Function(bool) onThemeChanged;
  final VoidCallback onLogout;

  const PodcastScreen({super.key, required this.isDarkMode, required this.onThemeChanged, required this.onLogout});

  @override
  State<PodcastScreen> createState() => _PodcastScreenState();
}

class _PodcastScreenState extends State<PodcastScreen> {
  final Stream<QuerySnapshot> _podcastsStream = FirebaseFirestore.instance.collection('podcasts').snapshots();
  
  html.AudioElement? _audioElement;
  String? _currentPlayingUrl;
  
  String _currentTitle = "Podcast en cours";
  String _currentDescription = "";
  String _currentImageUrl = "";
  
  bool _isPlaying = false;
  double _positionActuelle = 0.0;
  double _dureeTotale = 0.0;
  double _vitesseActuelle = 1.0; 
  String _categorieSelectionnee = "Tous";
  bool _afficherUniquementFavoris = false;
  
  List<String> _podcastsLikesIds = [];
  String _rechercheTexte = "";
  final TextEditingController _searchController = TextEditingController();

  final FocusNode _globalFocusNode = FocusNode();
  final FocusNode _searchFocusNode = FocusNode();

  bool _isPlayerExpanded = false;
  final List<double> _vitessesDisponibles = const [0.5, 0.75, 1.0, 1.25, 1.5, 2.0];

  @override
  void initState() {
    super.initState();
    _chargerFavoris();
  }

  @override
  void dispose() {
    _globalFocusNode.dispose();
    _searchFocusNode.dispose();
    _searchController.dispose();
    _audioElement?.pause();
    super.dispose();
  }

  void _chargerFavoris() {
    final String? jsonLikes = html.window.localStorage['podcasts_likes'];
    if (jsonLikes != null && jsonLikes.isNotEmpty) {
      try {
        final List<dynamic> listeDecodee = jsonDecode(jsonLikes);
        setState(() {
          _podcastsLikesIds = listeDecodee.map((item) => item.toString()).toList();
        });
      } catch (e) {
        _podcastsLikesIds = [];
      }
    }
  }

  void _basculerLike(String idDocument) {
    setState(() {
      if (_podcastsLikesIds.contains(idDocument)) {
        _podcastsLikesIds.remove(idDocument);
      } else {
        _podcastsLikesIds.add(idDocument);
      }
      html.window.localStorage['podcasts_likes'] = jsonEncode(_podcastsLikesIds);
    });
  }

  String _formaterTemps(double secondes) {
    if (secondes.isNaN || secondes.isInfinite) return "00:00";
    int minutes = (secondes / 60).floor();
    int secondesRestantes = (secondes % 60).floor();
    return '${minutes.toString().padLeft(2, '0')}:${secondesRestantes.toString().padLeft(2, '0')}';
  }

  void _selectionnerVitesse(double vitesse) {
    setState(() { _vitesseActuelle = vitesse; });
    if (_audioElement != null) { _audioElement!.playbackRate = _vitesseActuelle; }
  }

  void _gererLecture(String url, [Map<String, dynamic>? data]) {
    if (_isPlaying && _currentPlayingUrl == url) {
      _audioElement?.pause();
      setState(() { _isPlaying = false; });
    } 
    else if (!_isPlaying && _currentPlayingUrl == url && _audioElement != null) {
      _audioElement?.play();
      if (_audioElement != null) { _audioElement!.playbackRate = _vitesseActuelle; }
      setState(() { _isPlaying = true; });
    } 
    else {
      _audioElement?.pause();
      _audioElement = html.AudioElement(url);
      _audioElement?.play();
      if (_audioElement != null) { _audioElement!.playbackRate = _vitesseActuelle; }
      
      setState(() {
        _isPlaying = true;
        _currentPlayingUrl = url;
        _positionActuelle = 0.0;
        _dureeTotale = 0.0;
        
        if (data != null) {
          _currentTitle = data['Titre'] ?? data['titre'] ?? 'Sans titre';
          _currentDescription = data['Description'] ?? data['description'] ?? '';
          _currentImageUrl = data['image_url'] ?? data['imageUrl'] ?? '';
        }
      });

      _audioElement?.onTimeUpdate.listen((event) {
        if (mounted) {
          setState(() {
            _positionActuelle = (_audioElement?.currentTime ?? 0.0).toDouble();
            final d = (_audioElement?.duration ?? 0.0).toDouble();
            if (!d.isNaN) _dureeTotale = d;
          });
        }
      });

      _audioElement?.onEnded.listen((event) {
        if (mounted) {
          setState(() { _isPlaying = false; _positionActuelle = 0.0; });
        }
      });
    }
  }

  void _changerPosition(double secondes) {
    if (_audioElement != null) {
      final nouvellePosition = secondes.clamp(0.0, _dureeTotale > 0.0 ? _dureeTotale : 1.0);
      _audioElement!.currentTime = nouvellePosition;
      setState(() { _positionActuelle = nouvellePosition; });
    }
  }

  void _gererClavier(KeyEvent event) {
    if (_searchFocusNode.hasFocus) return;
    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.space) {
        if (_currentPlayingUrl != null) _gererLecture(_currentPlayingUrl!);
      } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
        _changerPosition(_positionActuelle + 10.0);
      } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
        _changerPosition(_positionActuelle - 10.0);
      }
    }
  }

  void _demanderCodeAdmin() {
    final TextEditingController codeController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: widget.isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        title: const Text("🔑 Espace Gestion Admin"),
        content: TextField(
          controller: codeController,
          obscureText: true,
          decoration: const InputDecoration(labelText: "Code d'accès secret Admin"),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Annuler")),
          ElevatedButton(
            onPressed: () {
              if (codeController.text == "AdminOrkyn2026") {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (context) => AdminUploadScreen(isDarkMode: widget.isDarkMode)));
              } else {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Code Admin incorrect ❌")));
              }
            },
            child: const Text("Valider"),
          )
        ],
      ),
    );
  }

  void _ouvrirNotifications(List<QueryDocumentSnapshot> podcasts) {
    setState(() { html.window.localStorage['last_check'] = DateTime.now().toIso8601String(); });
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: widget.isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              const Icon(Icons.notifications_active_rounded, color: Color(0xFFA855F7)),
              const SizedBox(width: 10),
              Text("Flux d'actualités", style: TextStyle(color: widget.isDarkMode ? Colors.white : Colors.black)),
            ],
          ),
          content: Container(
            width: 400,
            constraints: const BoxConstraints(maxHeight: 300), 
            child: podcasts.isEmpty 
              ? const Center(child: Text("Aucune nouvelle notification.", style: TextStyle(color: Colors.grey)))
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: podcasts.length > 5 ? 5 : podcasts.length,
                  itemBuilder: (context, index) {
                    final data = podcasts[podcasts.length - 1 - index].data() as Map<String, dynamic>;
                    final titre = data['Titre'] ?? data['titre'] ?? 'Nouveau Podcast';
                    return Card(
                      color: widget.isDarkMode ? const Color(0xFF2D2D2D) : const Color(0xFFF1F5F9),
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      child: ListTile(
                        leading: const Icon(Icons.radio_button_checked_rounded, color: Color(0xFF0EA5E9), size: 16),
                        title: Text(titre, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                        subtitle: const Text("Nouvel épisode disponible !", style: TextStyle(fontSize: 11)),
                        trailing: const Icon(Icons.play_arrow_rounded, color: Color(0xFFA855F7)),
                        onTap: () {
                          Navigator.pop(context);
                          final url = data['audio_url'] ?? data['audioUrl'] ?? '';
                          if (url.isNotEmpty) _gererLecture(url, data);
                        },
                      ),
                    );
                  },
                ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Fermer", style: TextStyle(color: Color(0xFFA855F7), fontWeight: FontWeight.bold))),
          ],
        );
      },
    );
  }

  Widget _buildPodcastCardHorizontal(String idDocument, Map<String, dynamic> podcast, Color cardColor, Color titleColor, Color subTitleColor) {
    final String audioUrl = podcast['audio_url'] ?? podcast['audioUrl'] ?? '';
    final String imageUrl = podcast['image_url'] ?? podcast['imageUrl'] ?? '';
    final String titre = podcast['Titre'] ?? podcast['titre'] ?? 'Sans titre';
    final bool isLiked = _podcastsLikesIds.contains(idDocument);

    return Container(
      width: 240,
      margin: const EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(widget.isDarkMode ? 0.2 : 0.03), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                GestureDetector(
                  onTap: () { if (audioUrl.isNotEmpty) _gererLecture(audioUrl, podcast); },
                  child: Container(
                    height: 130,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      image: DecorationImage(
                        image: NetworkImage(imageUrl.isNotEmpty ? imageUrl : 'https://picsum.photos/id/101/300/300'),
                        fit: BoxFit.cover,
                      ),
                    ),
                    child: Container(
                      color: _currentPlayingUrl == audioUrl && _isPlaying ? Colors.black.withOpacity(0.4) : Colors.black.withOpacity(0.1),
                      child: Center(
                        child: Icon(
                          _currentPlayingUrl == audioUrl && _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                          color: Colors.white, size: 45,
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 8, right: 8,
                  child: GestureDetector(
                    onTap: () => _basculerLike(idDocument),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(color: Colors.black38, shape: BoxShape.circle),
                      child: Icon(
                        isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                        color: isLiked ? Colors.redAccent : Colors.white, size: 18,
                      ),
                    ),
                  ),
                )
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(titre, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: titleColor)),
                  const SizedBox(height: 4),
                  Text(podcast['Description'] ?? podcast['description'] ?? 'Pas de description', maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, color: subTitleColor, height: 1.2)),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildPodcastCardVertical(String idDocument, Map<String, dynamic> podcast, Color cardColor, Color titleColor, Color subTitleColor) {
    final String audioUrl = podcast['audio_url'] ?? podcast['audioUrl'] ?? '';
    final String imageUrl = podcast['image_url'] ?? podcast['imageUrl'] ?? '';
    final String titre = podcast['Titre'] ?? podcast['titre'] ?? 'Sans titre';
    final String theme = podcast['Theme'] ?? podcast['theme'] ?? 'Général';
    final bool isLiked = _podcastsLikesIds.contains(idDocument);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Container(
        decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(widget.isDarkMode ? 0.2 : 0.04), blurRadius: 12, offset: const Offset(0, 4))]),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () { if (audioUrl.isNotEmpty) _gererLecture(audioUrl, podcast); },
                child: Container(
                  width: 90, height: 90,
                  decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(12), image: DecorationImage(image: NetworkImage(imageUrl.isNotEmpty ? imageUrl : 'https://picsum.photos/id/101/300/300'), fit: BoxFit.cover)),
                  child: Container(
                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: _currentPlayingUrl == audioUrl && _isPlaying ? Colors.black.withOpacity(0.4) : Colors.black.withOpacity(0.1)),
                    child: Icon(_currentPlayingUrl == audioUrl && _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded, color: Colors.white, size: 36),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(child: Text(titre, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: titleColor))),
                        IconButton(
                          padding: EdgeInsets.zero, constraints: const BoxConstraints(),
                          icon: Icon(isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded),
                          color: isLiked ? Colors.redAccent : Colors.grey, iconSize: 22,
                          onPressed: () => _basculerLike(idDocument),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(color: widget.isDarkMode ? const Color(0xFF2E1A47) : const Color(0xFFF5F3FF), borderRadius: BorderRadius.circular(20)),
                          child: Text(theme, style: const TextStyle(color: Color(0xFFA855F7), fontSize: 11, fontWeight: FontWeight.w500)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(podcast['Description'] ?? podcast['description'] ?? 'Pas de description', maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 13, color: subTitleColor, height: 1.2)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_searchFocusNode.hasFocus) _globalFocusNode.requestFocus();
    });

    final Color cardColor = widget.isDarkMode ? const Color(0xFF1E1E1E) : Colors.white;
    final Color barColor = widget.isDarkMode ? const Color(0xFF1A1A1A) : Colors.white;
    final Color searchFieldColor = widget.isDarkMode ? const Color(0xFF2D2D2D) : const Color(0xFFF1F5F9);
    final Color titleColor = widget.isDarkMode ? Colors.white : const Color(0xFF0F172A);
    final Color subTitleColor = widget.isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return KeyboardListener(
      focusNode: _globalFocusNode,
      onKeyEvent: _gererClavier,
      child: Scaffold(
        body: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: widget.isDarkMode 
                  ? const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF1A1A1A), Color(0xFF121212)])
                  : const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFF4F7F9), Color(0xFFE5EBF0)]),
              ),
              child: StreamBuilder<QuerySnapshot>(
                stream: _podcastsStream,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: Color(0xFF0066CC)));
                  }
                  if (snapshot.hasError) {
                    return const Center(child: Text('Erreur de connexion ❌', style: TextStyle(color: Colors.red)));
                  }
                  
                  final tousLesDocs = snapshot.data!.docs;
                  final Set<String> themesUniques = {"Tous"};
                  for (var doc in tousLesDocs) {
                    final data = doc.data() as Map<String, dynamic>;
                    final String? theme = data['Theme'] ?? data['theme'];
                    if (theme != null && theme.trim().isNotEmpty) themesUniques.add(theme.trim());
                  }

                  final listeFiltree = tousLesDocs.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final String idDoc = doc.id;
                    final String titre = (data['Titre'] ?? data['titre'] ?? 'Sans titre').toString().toLowerCase();
                    final String description = (data['Description'] ?? data['description'] ?? '').toString().toLowerCase();
                    final String theme = data['Theme'] ?? data['theme'] ?? '';

                    final bool correspondRecherche = titre.contains(_rechercheTexte.toLowerCase()) || description.contains(_rechercheTexte.toLowerCase());
                    final bool correspondCategorie = _categorieSelectionnee == "Tous" || theme.trim() == _categorieSelectionnee;
                    final bool correspondFavoris = !_afficherUniquementFavoris || _podcastsLikesIds.contains(idDoc);

                    return correspondRecherche && correspondCategorie && correspondFavoris;
                  }).toList();

                  bool aDesNouveautes = false;
                  final stringCheck = html.window.localStorage['last_check'];
                  if (stringCheck != null && tousLesDocs.isNotEmpty) { aDesNouveautes = true; }

                  return CustomScrollView(
                    slivers: [
                      SliverAppBar(
                        floating: true, pinned: true, centerTitle: true,
                        backgroundColor: barColor, elevation: 2, surfaceTintColor: barColor,
                        leading: IconButton(
                          icon: const Icon(Icons.admin_panel_settings_rounded, color: Color(0xFF94A3B8)),
                          tooltip: "Espace Admin",
                          onPressed: _demanderCodeAdmin,
                        ),
                        title: RichText(
                          text: const TextSpan(
                            children: [
                              TextSpan(text: "ORKYN' ", style: TextStyle(color: Color(0xFFA855F7), fontWeight: FontWeight.bold, fontSize: 20, letterSpacing: 1.2, fontFamily: 'Segoe UI')),
                              TextSpan(text: "Podcasts", style: TextStyle(color: Color(0xFF0EA5E9), fontWeight: FontWeight.w400, fontSize: 20, letterSpacing: 1.2, fontFamily: 'Segoe UI')),
                            ],
                          ),
                        ),
                        actions: [
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              IconButton(
                                icon: Icon(Icons.notifications_rounded, color: aDesNouveautes ? const Color(0xFF0EA5E9) : const Color(0xFF475569)),
                                onPressed: () => _ouvrirNotifications(tousLesDocs),
                              ),
                              if (aDesNouveautes)
                                Positioned(top: 10, right: 10, child: Container(width: 9, height: 9, decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle)))
                            ],
                          ),
                          IconButton(
                            icon: Icon(widget.isDarkMode ? Icons.wb_sunny_rounded : Icons.nightlight_round, color: widget.isDarkMode ? Colors.amber : const Color(0xFF475569)),
                            onPressed: () => widget.onThemeChanged(!widget.isDarkMode),
                          ),
                          IconButton(
                            icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
                            onPressed: () { _audioElement?.pause(); widget.onLogout(); },
                          ),
                          const SizedBox(width: 8),
                        ],
                      ),
                      SliverToBoxAdapter(
                        child: Container(
                          color: barColor,
                          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                          child: Row(
                            children: [
                              Expanded(
                                child: Container(
                                  height: 45,
                                  decoration: BoxDecoration(color: searchFieldColor, borderRadius: BorderRadius.circular(12)),
                                  child: TextField(
                                    controller: _searchController, focusNode: _searchFocusNode,
                                    style: TextStyle(color: widget.isDarkMode ? Colors.white : Colors.black),
                                    onChanged: (value) => setState(() { _rechercheTexte = value; }),
                                    decoration: InputDecoration(
                                      hintText: 'Rechercher un podcast...',
                                      hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
                                      prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF94A3B8), size: 20),
                                      suffixIcon: _rechercheTexte.isNotEmpty ? IconButton(icon: const Icon(Icons.clear_rounded, color: Color(0xFF94A3B8), size: 18), onPressed: () => setState(() { _searchController.clear(); _rechercheTexte = ""; })) : null,
                                      border: InputBorder.none, contentPadding: const EdgeInsets.symmetric(vertical: 11),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: Icon(_afficherUniquementFavoris ? Icons.favorite_rounded : Icons.favorite_border_rounded),
                                color: _afficherUniquementFavoris ? Colors.redAccent : const Color(0xFFA855F7),
                                tooltip: "Afficher mes favoris",
                                onPressed: () { setState(() { _afficherUniquementFavoris = !_afficherUniquementFavoris; }); },
                              ),
                              const SizedBox(width: 4),
                              Container(
                                height: 45, padding: const EdgeInsets.symmetric(horizontal: 12),
                                decoration: BoxDecoration(
                                  color: widget.isDarkMode ? const Color(0xFF2E1A47) : const Color(0xFFF5F3FF), 
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: widget.isDarkMode ? const Color(0xFF581C87) : const Color(0xFFE9D5FF), width: 1),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: _categorieSelectionnee,
                                    icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFFA855F7)),
                                    style: const TextStyle(color: Color(0xFFA855F7), fontWeight: FontWeight.w600, fontSize: 14, fontFamily: 'Segoe UI'),
                                    dropdownColor: widget.isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    onChanged: (String? newValue) { if (newValue != null) setState(() { _categorieSelectionnee = newValue; }); },
                                    items: themesUniques.map<DropdownMenuItem<String>>((String value) {
                                      return DropdownMenuItem<String>(value: value, child: Text(value, style: TextStyle(color: widget.isDarkMode ? Colors.white : Colors.black)));
                                    }).toList(),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      if (_categorieSelectionnee == "Tous" && _rechercheTexte.isEmpty && !_afficherUniquementFavoris) ...[
                        const SliverToBoxAdapter(
                          child: Padding(
                            padding: EdgeInsets.only(left: 24.0, top: 24.0, bottom: 12.0),
                            child: Text('✨ Nouveautés / Derniers ajouts', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                          ),
                        ),
                        SliverToBoxAdapter(
                          child: SizedBox(
                            height: 220,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal, padding: const EdgeInsets.only(left: 24.0),
                              itemCount: listeFiltree.length,
                              itemBuilder: (context, index) {
                                final doc = listeFiltree[listeFiltree.length - 1 - index];
                                return _buildPodcastCardHorizontal(doc.id, doc.data() as Map<String, dynamic>, cardColor, titleColor, subTitleColor);
                              },
                            ),
                          ),
                        ),
                        const SliverToBoxAdapter(
                          child: Padding(
                            padding: EdgeInsets.only(left: 24.0, top: 28.0, bottom: 12.0),
                            child: Text('🔥 Sélection Orkyn\' / Les plus pertinents', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                          ),
                        ),
                        SliverToBoxAdapter(
                          child: SizedBox(
                            height: 220,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal, padding: const EdgeInsets.only(left: 24.0),
                              itemCount: listeFiltree.length > 3 ? 3 : listeFiltree.length,
                              itemBuilder: (context, index) {
                                final doc = listeFiltree[index];
                                return _buildPodcastCardHorizontal(doc.id, doc.data() as Map<String, dynamic>, cardColor, titleColor, subTitleColor);
                              },
                            ),
                          ),
                        ),
                        const SliverToBoxAdapter(child: SizedBox(height: 120)), 
                      ] else ...[
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.only(left: 24.0, top: 16.0, bottom: 8.0),
                            child: Text(_afficherUniquementFavoris ? '❤️ Mes Podcasts Likés' : (_rechercheTexte.isNotEmpty ? 'Résultats' : 'Thème : $_categorieSelectionnee'), style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: titleColor)),
                          ),
                        ),
                        if (listeFiltree.isEmpty)
                          const SliverFillRemaining(child: Center(child: Text('Aucun podcast trouvé.', style: TextStyle(color: Colors.grey, fontSize: 14))))
                        else
                          SliverList(
                            delegate: SliverChildBuilderDelegate((context, index) {
                              final doc = listeFiltree[index];
                              return _buildPodcastCardVertical(doc.id, doc.data() as Map<String, dynamic>, cardColor, titleColor, subTitleColor);
                            }, childCount: listeFiltree.length),
                          ),
                        const SliverToBoxAdapter(child: SizedBox(height: 120)),
                      ]
                    ],
                  );
                },
              ),
            ),

            if (_currentPlayingUrl != null)
              AnimatedPositioned(
                duration: const Duration(milliseconds: 350), curve: Curves.easeInOut,
                bottom: 0, left: 0, right: 0,
                height: _isPlayerExpanded ? MediaQuery.of(context).size.height : 75,
                child: Container(
                  decoration: BoxDecoration(
                    color: widget.isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 15, offset: const Offset(0, -4))],
                    borderRadius: _isPlayerExpanded ? BorderRadius.zero : const BorderRadius.vertical(top: Radius.circular(16)),
                  ),
                  child: _isPlayerExpanded ? _buildFullPlayer(titleColor, subTitleColor) : _buildMiniPlayer(titleColor), 
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniPlayer(Color titleColor) {
    return Column(
      children: [
        LinearProgressIndicator(
          value: _dureeTotale > 0 ? (_positionActuelle / _dureeTotale) : 0,
          backgroundColor: widget.isDarkMode ? const Color(0xFF2D2D2D) : const Color(0xFFE2E8F0),
          valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFA855F7)), minHeight: 3,
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                IconButton(icon: const Icon(Icons.keyboard_arrow_up_rounded, color: Color(0xFF0EA5E9), size: 28), onPressed: () => setState(() => _isPlayerExpanded = true)),
                const SizedBox(width: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: _currentImageUrl.isNotEmpty ? Image.network(_currentImageUrl, width: 40, height: 40, fit: BoxFit.cover) : Container(color: Colors.purple.withOpacity(0.2), width: 40, height: 40, child: const Icon(Icons.music_note, size: 20, color: Color(0xFFA855F7))),
                ),
                const SizedBox(width: 12),
                Expanded(child: Text(_currentTitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: titleColor))),
                Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: const Color(0xFFA855F7).withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: Text('${_vitesseActuelle}x', style: const TextStyle(color: Color(0xFFA855F7), fontWeight: FontWeight.bold, fontSize: 12))),
                const SizedBox(width: 8),
                IconButton(icon: const Icon(Icons.replay_10_rounded, size: 24, color: Colors.grey), onPressed: () => _changerPosition(_positionActuelle - 10.0)),
                IconButton(icon: Icon(_isPlaying ? Icons.pause_circle_filled_rounded : Icons.play_circle_filled_rounded), iconSize: 38, color: const Color(0xFFA855F7), onPressed: () => _gererLecture(_currentPlayingUrl!)),
                IconButton(icon: const Icon(Icons.forward_10_rounded, size: 24, color: Colors.grey), onPressed: () => _changerPosition(_positionActuelle + 10.0)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTapisVitesses() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text("Tapis Déroulant des Vitesses", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 0.5)),
        const SizedBox(height: 8),
        SizedBox(
          height: 42,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal, physics: const BouncingScrollPhysics(),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: _vitessesDisponibles.map((vitesse) {
                final bool isSelected = _vitesseActuelle == vitesse;
                return GestureDetector(
                  onTap: () => _selectionnerVitesse(vitesse),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200), margin: const EdgeInsets.symmetric(horizontal: 6), padding: const EdgeInsets.symmetric(horizontal: 16), alignment: Alignment.center,
                    decoration: BoxDecoration(color: isSelected ? const Color(0xFFA855F7) : (widget.isDarkMode ? const Color(0xFF2D2D2D) : const Color(0xFFE2E8F0)), borderRadius: BorderRadius.circular(20), boxShadow: isSelected ? [BoxShadow(color: const Color(0xFFA855F7).withOpacity(0.4), blurRadius: 8, offset: const Offset(0, 3))] : []),
                    child: Text('${vitesse}x', style: TextStyle(color: isSelected ? Colors.white : (widget.isDarkMode ? Colors.white70 : Colors.black87), fontWeight: isSelected ? FontWeight.bold : FontWeight.w500, fontSize: 14)),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        if (_vitesseActuelle != 1.0) ...[const SizedBox(height: 2), const Icon(Icons.arrow_drop_up_rounded, color: Color(0xFFA855F7), size: 18)]
      ],
    );
  }

  Widget _buildFullPlayer(Color titleColor, Color subTitleColor) {
    return Scaffold(
      backgroundColor: widget.isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent, elevation: 0,
        leading: IconButton(icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 36), onPressed: () => setState(() => _isPlayerExpanded = false)),
        title: Text("LECTURE EN COURS", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.5, color: subTitleColor)), centerTitle: true,
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final double imageSize = (constraints.maxHeight * 0.32).clamp(130.0, 240.0);
            final double spaceBetween = (constraints.maxHeight * 0.02).clamp(6.0, 18.0);
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
              child: Column(
                children: [
                  Center(child: Container(width: imageSize, height: imageSize, decoration: BoxDecoration(borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.25), blurRadius: 20, offset: const Offset(0, 8))], image: DecorationImage(image: NetworkImage(_currentImageUrl.isNotEmpty ? _currentImageUrl : 'https://picsum.photos/id/101/400/400'), fit: BoxFit.cover)))),
                  SizedBox(height: spaceBetween),
                  Align(alignment: Alignment.centerLeft, child: Text(_currentTitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: titleColor))),
                  const SizedBox(height: 6),
                  
                  // Zone de la description corrigée avec défilement et affichage total
                  Expanded(
                    child: Align(
                      alignment: Alignment.topLeft,
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: Text(
                          _currentDescription, 
                          style: TextStyle(fontSize: 13, color: subTitleColor, height: 1.4),
                        ),
                      ),
                    ),
                  ),
                  
                  SizedBox(height: spaceBetween),
                  Slider(activeColor: const Color(0xFFA855F7), inactiveColor: widget.isDarkMode ? const Color(0xFF334155) : const Color(0xFFE2E8F0), min: 0.0, max: _dureeTotale > 0 ? _dureeTotale : 1.0, value: _positionActuelle.clamp(0.0, _dureeTotale > 0 ? _dureeTotale : 1.0), onChanged: (val) => _changerPosition(val)),
                  Padding(padding: const EdgeInsets.symmetric(horizontal: 16.0), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(_formaterTemps(_positionActuelle), style: TextStyle(fontSize: 12, color: subTitleColor)), Text(_formaterTemps(_dureeTotale), style: TextStyle(fontSize: 12, color: subTitleColor))])),
                  SizedBox(height: spaceBetween),
                  _buildTapisVitesses(),
                  SizedBox(height: spaceBetween),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(icon: const Icon(Icons.replay_10_rounded), iconSize: 36, color: titleColor, onPressed: () => _changerPosition(_positionActuelle - 10.0)),
                      const SizedBox(width: 24),
                      IconButton(icon: Icon(_isPlaying ? Icons.pause_circle_filled_rounded : Icons.play_circle_filled_rounded), iconSize: 64, color: const Color(0xFFA855F7), onPressed: () => _gererLecture(_currentPlayingUrl!)),
                      const SizedBox(width: 24),
                      IconButton(icon: const Icon(Icons.forward_10_rounded), iconSize: 36, color: titleColor, onPressed: () => _changerPosition(_positionActuelle + 10.0)),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class AdminUploadScreen extends StatefulWidget {
  final bool isDarkMode;
  const AdminUploadScreen({super.key, required this.isDarkMode});

  @override
  State<AdminUploadScreen> createState() => _AdminUploadScreenState();
}

class _AdminUploadScreenState extends State<AdminUploadScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _themeController = TextEditingController();
  final _audioUrlController = TextEditingController();
  final _imageUrlController = TextEditingController();
  bool _enCoursEnvoi = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _themeController.dispose();
    _audioUrlController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  void _publierPodcast() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() { _enCoursEnvoi = true; });

    try {
      await FirebaseFirestore.instance.collection('podcasts').add({
        'Titre': _titleController.text.trim(),
        'Description': _descriptionController.text.trim(),
        'Theme': _themeController.text.trim().isEmpty ? 'Général' : _themeController.text.trim(),
        'audio_url': _audioUrlController.text.trim(),
        'image_url': _imageUrlController.text.trim().isEmpty ? 'https://picsum.photos/id/101/400/400' : _imageUrlController.text.trim(),
        'date_ajout': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(backgroundColor: Colors.green, content: Text("Podcast ajouté avec succès ! 🎉")));
      Navigator.pop(context); 
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(backgroundColor: Colors.red, content: Text("Erreur d'envoi : $e")));
    } finally {
      setState(() { _enCoursEnvoi = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Ajouter un Podcast"),
        backgroundColor: widget.isDarkMode ? const Color(0xFF1A1A1A) : Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text("Formulaire de publication rapide", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              const Text("Le podcast sera instantanément disponible pour tous les collaborateurs.", style: TextStyle(color: Colors.grey, fontSize: 13)),
              const SizedBox(height: 24),
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(labelText: "Titre du podcast *", prefixIcon: const Icon(Icons.title_rounded), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                validator: (v) => v == null || v.trim().isEmpty ? "Champ obligatoire" : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: InputDecoration(labelText: "Description / Notes de l'épisode *", prefixIcon: const Icon(Icons.description_rounded), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                validator: (v) => v == null || v.trim().isEmpty ? "Champ obligatoire" : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _themeController,
                decoration: InputDecoration(labelText: "Thème / Catégorie (ex: RH, Formation, Sécurité)", prefixIcon: const Icon(Icons.label_rounded), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _audioUrlController,
                decoration: InputDecoration(labelText: "URL du fichier audio (.mp3) *", hintText: "https://example.com/audio.mp3", prefixIcon: const Icon(Icons.audiotrack_rounded), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                validator: (v) => v == null || v.trim().isEmpty ? "Champ obligatoire" : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _imageUrlController,
                decoration: InputDecoration(labelText: "URL de la jaquette/image (Optionnel)", hintText: "https://example.com/image.jpg", prefixIcon: const Icon(Icons.image_rounded), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
              ),
              const SizedBox(height: 32),
              _enCoursEnvoi
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFFA855F7)))
                  : ElevatedButton.icon(
                      onPressed: _publierPodcast,
                      icon: const Icon(Icons.cloud_upload_rounded),
                      label: const Text("Publier le podcast", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFA855F7),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}