import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:html' as html;
import 'dart:convert';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Initialisation directe et robuste pour Flutter Web
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
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _isAlreadyAuthenticated = html.window.localStorage['orkyn_auth'] == 'true';
    _isAdmin = html.window.localStorage['orkyn_admin'] == 'true';
    final String? themeSauvegarde = html.window.localStorage['theme_mode'];
    _themeMode = (themeSauvegarde == 'dark') ? ThemeMode.dark : ThemeMode.light;
    
    // Interception automatique du lien magique s'il est présent dans l'URL
    _verifierLienDeConnexion();
  }

  Future<void> _verifierLienDeConnexion() async {
    final String currentUrl = html.window.location.href;
    if (FirebaseAuth.instance.isSignInWithEmailLink(currentUrl)) {
      String? email = html.window.localStorage['emailForSignIn'];
      if (email != null) {
        try {
          UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailLink(
            email: email,
            emailLink: currentUrl,
          );
          
          // Détection automatique du rôle Admin si l'adresse e-mail correspond
          // (Pense à laisser ton e-mail exact ici)
          bool estAdmin = (userCredential.user?.email == "ilyan.tajmouti@orkyn.fr" || userCredential.user?.email == "alexis.mary@orkyn.fr");
          
          html.window.localStorage['orkyn_auth'] = 'true';
          html.window.localStorage['orkyn_admin'] = estAdmin ? 'true' : 'false';
          
          setState(() {
            _isAlreadyAuthenticated = true;
            _isAdmin = estAdmin;
          });
          
          // Nettoyer l'URL pour enlever les paramètres Firebase complexes de la barre d'adresse
          html.window.history.replaceState(null, '', html.window.location.pathname);
        } catch (e) {
          // Lien invalide ou expiré
        }
      }
    }
  }

  void _changerTheme(bool passerEnSombre) {
    setState(() {
      _themeMode = passerEnSombre ? ThemeMode.dark : ThemeMode.light;
      html.window.localStorage['theme_mode'] = passerEnSombre ? 'dark' : 'light';
    });
  }

  void _validerConnexion(bool connecte, bool admin) {
    setState(() { 
      _isAlreadyAuthenticated = connecte; 
      _isAdmin = admin;
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
              isAdmin: _isAdmin,
              isDarkMode: _themeMode == ThemeMode.dark,
              onThemeChanged: _changerTheme,
              onLogout: () async {
                await FirebaseAuth.instance.signOut();
                html.window.localStorage.remove('orkyn_auth');
                html.window.localStorage.remove('orkyn_admin');
                html.window.localStorage.remove('emailForSignIn');
                _validerConnexion(false, false);
              },
            )
          : AuthScreen(
              isDarkMode: _themeMode == ThemeMode.dark,
              onThemeChanged: _changerTheme,
              onLoginSuccess: (admin) => _validerConnexion(true, admin),
            ),
    );
  }
}

class AuthScreen extends StatefulWidget {
  final bool isDarkMode;
  final Function(bool) onThemeChanged;
  final Function(bool) onLoginSuccess;
  const AuthScreen({super.key, required this.isDarkMode, required this.onThemeChanged, required this.onLoginSuccess});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _emailController = TextEditingController();
  String _message = "";
  bool _isLoading = false;
  bool _mailEnvoye = false;

  void _demanderLienDeConnexion() async {
    final email = _emailController.text.trim().toLowerCase();

    if (email.isEmpty) {
      setState(() { _message = "Veuillez entrer votre adresse e-mail."; });
      return;
    }
    if (!email.endsWith('@orkyn.fr') && !email.endsWith('@airliquide.com')) {
      setState(() { _message = "Accès refusé : adresse @orkyn.fr ou @airliquide.com requise."; });
      return;
    }

    setState(() { 
      _isLoading = true; 
      _message = "";
    });

    try {
      // FIX CORRECTION URL DE RETOUR GITHUB PAGES
      final String currentUrl = html.window.location.href;
      final String baseUrl = currentUrl.contains('localhost') 
          ? 'http://localhost:${html.window.location.port}/'
          : 'https://orkyn-al.github.io/ORKYN-Podcasts/';

      var acs = ActionCodeSettings(
        url: baseUrl,
        handleCodeInApp: true,
      );

      await FirebaseAuth.instance.sendSignInLinkToEmail(
        email: email,
        actionCodeSettings: acs,
      );

      html.window.localStorage['emailForSignIn'] = email;
      
      setState(() {
        _mailEnvoye = true;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _message = "Une erreur est survenue lors de l'envoi du mail.";
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Color cardColor = widget.isDarkMode ? const Color(0xFF1E1E1E) : Colors.white;
    final Color textColor = widget.isDarkMode ? Colors.white : const Color(0xFF0F172A);

    return Scaffold(
      body: Stack(
        children: [
          Positioned(
            top: 16, right: 16,
            child: IconButton(
              icon: Icon(widget.isDarkMode ? Icons.wb_sunny_rounded : Icons.nightlight_round, color: widget.isDarkMode ? Colors.amber : const Color(0xFF475569)),
              onPressed: () => widget.onThemeChanged(!widget.isDarkMode),
            ),
          ),
          Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 400),
              padding: const EdgeInsets.all(32.0),
              decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 20, offset: const Offset(0, 8))]),
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
                  if (!_mailEnvoye) ...[
                    TextField(
                      controller: _emailController,
                      style: TextStyle(color: widget.isDarkMode ? Colors.white : Colors.black),
                      decoration: InputDecoration(labelText: "Votre e-mail pro", hintText: "prenom.nom@orkyn.fr", prefixIcon: const Icon(Icons.email_rounded), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                      onSubmitted: (_) => _demanderLienDeConnexion(),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _demanderLienDeConnexion,
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFA855F7), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                      child: _isLoading 
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text("Recevoir mon lien de connexion", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                    ),
                  ] else ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                      child: const Column(
                        children: [
                          Icon(Icons.mark_email_read_rounded, color: Colors.green, size: 48),
                          SizedBox(height: 12),
                          Text("Lien envoyé !", style: TextStyle(color: Colors.green, fontSize: 16, fontWeight: FontWeight.bold)),
                          SizedBox(height: 8),
                          Text("Consultez votre boîte mail pro et cliquez sur le lien reçu pour vous connecter.", textAlign: TextAlign.center, style: TextStyle(fontSize: 13, height: 1.4)),
                        ],
                      ),
                    ),
                  ],
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
  final bool isAdmin;
  final bool isDarkMode;
  final Function(bool) onThemeChanged;
  final VoidCallback onLogout;
  const PodcastScreen({super.key, required this.isAdmin, required this.isDarkMode, required this.onThemeChanged, required this.onLogout});

  @override
  State<PodcastScreen> createState() => _PodcastScreenState();
}

class _PodcastScreenState extends State<PodcastScreen> {
  final Stream<QuerySnapshot> _podcastsStream = FirebaseFirestore.instance.collection('podcasts').snapshots();
  html.AudioElement? _audioElement;
  String? _currentPlayingUrl;
  String _currentTitle = "Podcast en cours";
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
  bool _lienPartageTraite = false;

  Map<String, dynamic>? _serieSelectionneeData;
  List<DocumentSnapshot> _chapitresDeLaSerie = [];
  DocumentSnapshot? _grosPodcastIntegral;

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
        setState(() { _podcastsLikesIds = listeDecodee.map((item) => item.toString()).toList(); });
      } catch (e) { _podcastsLikesIds = []; }
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

  void _vitesseSelectionnee(double vitesse) {
    setState(() { _vitesseActuelle = vitesse; });
    if (_audioElement != null) { _audioElement!.playbackRate = _vitesseActuelle; }
  }

  void _partagerPodcast(String idDocument, String titre) {
    final String urlActuelle = html.window.location.href.split('?').first;
    final String lienDePartage = "$urlActuelle?id=$idDocument";
    html.window.navigator.clipboard?.writeText(lienDePartage);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Lien copié pour : $titre 🔗"), backgroundColor: const Color(0xFF0EA5E9), duration: const Duration(seconds: 2)));
  }

  void _verifierLienDePartage(List<QueryDocumentSnapshot> tousLesPodcasts) {
    if (_lienPartageTraite) return;
    final uri = Uri.parse(html.window.location.href);
    final String? idPartage = uri.queryParameters['id'];
    if (idPartage != null && idPartage.isNotEmpty) {
      _lienPartageTraite = true;
      try {
        final docTrouve = tousLesPodcasts.firstWhere((doc) => doc.id == idPartage);
        final data = docTrouve.data() as Map<String, dynamic>;
        WidgetsBinding.instance.addPostFrameCallback((_) { _clicSurPodcast(data, tousLesPodcasts); });
      } catch (e) {}
    }
  }

  void _clicSurPodcast(Map<String, dynamic> podcastData, List<QueryDocumentSnapshot> tousLesPodcasts) {
    final String titre = (podcastData['Titre'] ?? '').toString();
    final String audioUrl = podcastData['audio_url'] ?? '';

    if (titre.contains('[Série]')) {
      final String themeSerie = podcastData['Theme'] ?? 'management';
      final List<DocumentSnapshot> tousLesMorceaux = tousLesPodcasts.where((doc) => (doc.data() as Map<String, dynamic>)['Theme'] == themeSerie).toList();
      DocumentSnapshot? integralDoc;
      final List<DocumentSnapshot> listeChapitres = [];

      for (var doc in tousLesMorceaux) {
        final d = doc.data() as Map<String, dynamic>;
        if (d['Titre'].toString().contains('[Série]')) { integralDoc = doc; } else { listeChapitres.add(doc); }
      }

      listeChapitres.sort((a, b) {
        final tA = (a.data() as Map<String, dynamic>)['Titre']?.toString() ?? '';
        final tB = (b.data() as Map<String, dynamic>)['Titre']?.toString() ?? '';
        int numP(String t) => t.contains('Partie') ? (int.tryParse(t.split('Partie').last.trim()) ?? 0) : 0;
        return numP(tA).compareTo(numP(tB));
      });

      setState(() { _serieSelectionneeData = podcastData; _grosPodcastIntegral = integralDoc; _chapitresDeLaSerie = listeChapitres; });
    } else {
      if (audioUrl.isNotEmpty) _gererLecture(audioUrl, podcastData);
    }
  }

  void _gererLecture(String url, [Map<String, dynamic>? data]) {
    if (_isPlaying && _currentPlayingUrl == url) {
      _audioElement?.pause();
      setState(() { _isPlaying = false; });
    } else if (!_isPlaying && _currentPlayingUrl == url && _audioElement != null) {
      _audioElement?.play();
      _audioElement!.playbackRate = _vitesseActuelle;
      setState(() { _isPlaying = true; });
    } else {
      _audioElement?.pause();
      _audioElement = html.AudioElement(url)..play();
      _audioElement!.playbackRate = _vitesseActuelle;
      setState(() {
        _isPlaying = true;
        _currentPlayingUrl = url;
        _positionActuelle = 0.0;
        _dureeTotale = 0.0;
        if (data != null) {
          _currentTitle = data['Titre'] ?? 'Sans titre';
          _currentImageUrl = data['image_url'] ?? '';
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
          int idx = _chapitresDeLaSerie.indexWhere((doc) => ((doc.data() as Map<String, dynamic>)['audio_url'] ?? '') == _currentPlayingUrl);
          if (idx != -1 && idx + 1 < _chapitresDeLaSerie.length) {
            final nxtData = _chapitresDeLaSerie[idx + 1].data() as Map<String, dynamic>;
            if ((nxtData['audio_url'] ?? '').isNotEmpty) { _gererLecture(nxtData['audio_url'], nxtData); return; }
          }
          setState(() { _isPlaying = false; _positionActuelle = 0.0; }); 
        }
      });
    }
  }

  void _changerPosition(double secondes) {
    if (_audioElement != null) {
      final nPos = secondes.clamp(0.0, _dureeTotale > 0.0 ? _dureeTotale : 1.0);
      _audioElement!.currentTime = nPos;
      setState(() { _positionActuelle = nPos; });
    }
  }

  void _gererClavier(KeyEvent event) {
    if (_searchFocusNode.hasFocus) return;
    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.space) { if (_currentPlayingUrl != null) _gererLecture(_currentPlayingUrl!); }
      else if (event.logicalKey == LogicalKeyboardKey.arrowRight) { _changerPosition(_positionActuelle + 10.0); }
      else if (event.logicalKey == LogicalKeyboardKey.arrowLeft) { _changerPosition(_positionActuelle - 10.0); }
    }
  }

  void _ouvrirOutilAdmin({DocumentSnapshot? docAModifier}) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => AdminUploadScreen(isDarkMode: widget.isDarkMode, podcastDoc: docAModifier)));
  }

  void _ouvrirNotifications(List<QueryDocumentSnapshot> podcasts) {
    setState(() { html.window.localStorage['last_check'] = DateTime.now().toIso8601String(); });
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: widget.isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(children: [Icon(Icons.notifications_active_rounded, color: Color(0xFFA855F7)), SizedBox(width: 10), Text("Flux d'actualités")]),
          content: Container(
            width: 400, constraints: const BoxConstraints(maxHeight: 300), 
            child: podcasts.isEmpty 
              ? const Center(child: Text("Aucune notification.", style: TextStyle(color: Colors.grey)))
              : ListView.builder(
                  shrinkWrap: true, itemCount: podcasts.length > 5 ? 5 : podcasts.length,
                  itemBuilder: (context, index) {
                    final data = podcasts[podcasts.length - 1 - index].data() as Map<String, dynamic>;
                    return Card(
                      color: widget.isDarkMode ? const Color(0xFF2D2D2D) : const Color(0xFFF1F5F9),
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      child: ListTile(
                        leading: const Icon(Icons.radio_button_checked_rounded, color: Color(0xFF0EA5E9), size: 16),
                        title: Text(data['Titre'] ?? 'Nouveau Podcast', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                        subtitle: const Text("Disponible !", style: TextStyle(fontSize: 11)),
                        trailing: const Icon(Icons.play_arrow_rounded, color: Color(0xFFA855F7)),
                        onTap: () { Navigator.pop(context); final url = data['audio_url'] ?? ''; if (url.isNotEmpty) _gererLecture(url, data); },
                      ),
                    );
                  },
                ),
          ),
        );
      },
    );
  }

  Widget _buildPodcastCardHorizontal(DocumentSnapshot doc, Color cardColor, Color titleColor, Color subTitleColor, List<QueryDocumentSnapshot> tousLesPodcasts) {
    final Map<String, dynamic> podcast = doc.data() as Map<String, dynamic>;
    final String audioUrl = podcast['audio_url'] ?? '';
    final String imageUrl = podcast['image_url'] ?? '';
    final bool isLiked = _podcastsLikesIds.contains(doc.id);
    final bool estUneSerie = (podcast['Titre'] ?? '').toString().contains('[Série]');

    return Container(
      width: 240, margin: const EdgeInsets.only(right: 16),
      decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(widget.isDarkMode ? 0.2 : 0.03), blurRadius: 8, offset: const Offset(0, 2))]),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                GestureDetector(
                  onTap: () => _clicSurPodcast(podcast, tousLesPodcasts),
                  child: Container(
                    height: 130, width: double.infinity,
                    decoration: BoxDecoration(color: const Color(0xFF1E293B), image: DecorationImage(image: NetworkImage(imageUrl.isNotEmpty ? imageUrl : 'https://picsum.photos/id/101/300/300'), fit: BoxFit.cover)),
                    child: Container(
                      color: _currentPlayingUrl == audioUrl && _isPlaying ? Colors.black.withOpacity(0.4) : Colors.black.withOpacity(0.1),
                      child: Center(child: Icon(estUneSerie ? Icons.album_rounded : (_currentPlayingUrl == audioUrl && _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded), color: Colors.white, size: 45)),
                    ),
                  ),
                ),
                Positioned(top: 8, right: 8, child: GestureDetector(onTap: () => _basculerLike(doc.id), child: Container(padding: const EdgeInsets.all(6), decoration: const BoxDecoration(color: Colors.black38, shape: BoxShape.circle), child: Icon(isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded, color: isLiked ? Colors.redAccent : Colors.white, size: 18)))),
                if (widget.isAdmin)
                  Positioned(top: 8, left: 8, child: GestureDetector(onTap: () => _ouvrirOutilAdmin(docAModifier: doc), child: Container(padding: const EdgeInsets.all(6), decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle), child: const Icon(Icons.settings_rounded, color: Colors.white, size: 18)))),
                Positioned(bottom: 8, right: 8, child: GestureDetector(onTap: () => _partagerPodcast(doc.id, podcast['Titre'] ?? 'Sans titre'), child: Container(padding: const EdgeInsets.all(6), decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle), child: const Icon(Icons.share_rounded, color: Colors.white, size: 16)))),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(podcast['Titre'] ?? 'Sans titre', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: titleColor)),
                  const SizedBox(height: 4),
                  Text(podcast['Description'] ?? '', maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, color: subTitleColor, height: 1.2)),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildPodcastCardVertical(DocumentSnapshot doc, Color cardColor, Color titleColor, Color subTitleColor, List<QueryDocumentSnapshot> tousLesPodcasts) {
    final Map<String, dynamic> podcast = doc.data() as Map<String, dynamic>;
    final String audioUrl = podcast['audio_url'] ?? '';
    final String imageUrl = podcast['image_url'] ?? '';
    final bool isLiked = _podcastsLikesIds.contains(doc.id);
    final bool estUneSerie = (podcast['Titre'] ?? '').toString().contains('[Série]');

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
                onTap: () => _clicSurPodcast(podcast, tousLesPodcasts),
                child: Container(
                  width: 90, height: 90,
                  decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(12), image: DecorationImage(image: NetworkImage(imageUrl.isNotEmpty ? imageUrl : 'https://picsum.photos/id/101/300/300'), fit: BoxFit.cover)),
                  child: Container(
                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: _currentPlayingUrl == audioUrl && _isPlaying ? Colors.black.withOpacity(0.4) : Colors.black.withOpacity(0.1)),
                    child: Icon(estUneSerie ? Icons.album_rounded : (_currentPlayingUrl == audioUrl && _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded), color: Colors.white, size: 36),
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
                        Expanded(child: Text(podcast['Titre'] ?? 'Sans titre', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: titleColor))),
                        IconButton(padding: EdgeInsets.zero, constraints: const BoxConstraints(), icon: const Icon(Icons.share_rounded, color: Colors.grey, size: 18), onPressed: () => _partagerPodcast(doc.id, podcast['Titre'] ?? 'Sans titre')),
                        if (widget.isAdmin) ...[
                          const SizedBox(width: 4),
                          IconButton(padding: EdgeInsets.zero, constraints: const BoxConstraints(), icon: const Icon(Icons.settings_rounded, color: Colors.grey, size: 18), onPressed: () => _ouvrirOutilAdmin(docAModifier: doc)),
                        ],
                        const SizedBox(width: 4),
                        IconButton(padding: EdgeInsets.zero, constraints: const BoxConstraints(), icon: Icon(isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded), color: isLiked ? Colors.redAccent : Colors.grey, iconSize: 20, onPressed: () => _basculerLike(doc.id)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), decoration: BoxDecoration(color: widget.isDarkMode ? const Color(0xFF2E1A47) : const Color(0xFFF5F3FF), borderRadius: BorderRadius.circular(20)), child: Text(podcast['Theme'] ?? 'Général', style: const TextStyle(color: Color(0xFFA855F7), fontSize: 11, fontWeight: FontWeight.w500))),
                    const SizedBox(height: 8),
                    Text(podcast['Description'] ?? '', maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 13, color: subTitleColor, height: 1.2)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVueAlbumSerie(Color titleColor, Color subTitleColor, Color cardColor) {
    final String imageSerie = _serieSelectionneeData?['image_url'] ?? '';
    final String descriptionSerie = _serieSelectionneeData?['Description'] ?? '';

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_rounded, size: 28), onPressed: () => setState(() => _serieSelectionneeData = null)),
        title: const Text("MANAGEMENT", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(24.0),
        children: [
          Center(
            child: Container(
              width: 180, height: 180,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 15, offset: const Offset(0, 8))],
                image: DecorationImage(image: NetworkImage(imageSerie.isNotEmpty ? imageSerie : 'https://picsum.photos/id/101/400/400'), fit: BoxFit.cover),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Center(child: Text("MANAGEMENT", textAlign: TextAlign.center, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: titleColor))),
          const SizedBox(height: 8),
          Padding(padding: const EdgeInsets.symmetric(horizontal: 16.0), child: Text(descriptionSerie, textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: subTitleColor, height: 1.4))),
          const SizedBox(height: 24),
          Divider(color: Colors.grey.withOpacity(0.1)),
          const SizedBox(height: 12),

          if (_grosPodcastIntegral != null) ...[
            Text("ÉMISSION COMPLÈTE (INTÉGRALE)", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: subTitleColor, letterSpacing: 1.2)),
            const SizedBox(height: 10),
            Builder(builder: (context) {
              final data = _grosPodcastIntegral!.data() as Map<String, dynamic>;
              final String url = data['audio_url'] ?? '';
              final bool enCours = _currentPlayingUrl == url;
              final bool isGrosLiked = _podcastsLikesIds.contains(_grosPodcastIntegral!.id);

              return Card(
                color: enCours ? const Color(0xFFA855F7).withOpacity(0.15) : const Color(0xFFA855F7).withOpacity(0.05),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: Color(0xFFA855F7), width: 1)),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: IconButton(icon: Icon(enCours && _isPlaying ? Icons.pause_circle_filled_rounded : Icons.play_circle_filled_rounded, color: const Color(0xFFA855F7), size: 36), onPressed: () { if (url.isNotEmpty) _gererLecture(url, data); }),
                  title: Text(data['Titre'] ?? 'Podcast Intégral', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: enCours ? const Color(0xFFA855F7) : titleColor)),
                  subtitle: const Text("Écouter la slide en entier", style: TextStyle(fontSize: 12)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(icon: const Icon(Icons.share_rounded, color: Colors.grey, size: 18), onPressed: () => _partagerPodcast(_grosPodcastIntegral!.id, data['Titre'] ?? 'Sans titre')),
                      if (widget.isAdmin) IconButton(icon: const Icon(Icons.settings_rounded, color: Colors.grey, size: 18), onPressed: () => _ouvrirOutilAdmin(docAModifier: _grosPodcastIntegral)),
                      IconButton(icon: Icon(isGrosLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded, color: isGrosLiked ? Colors.redAccent : Colors.grey, size: 20), onPressed: () => _basculerLike(_grosPodcastIntegral!.id)),
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: 24),
          ],

          Text("CHAPITRES DE LA SLIDE (${_chapitresDeLaSerie.length})", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: subTitleColor, letterSpacing: 1.2)),
          const SizedBox(height: 12),
          ..._chapitresDeLaSerie.map((doc) {
            final ep = doc.data() as Map<String, dynamic>;
            final String url = ep['audio_url'] ?? '';
            final bool enCours = _currentPlayingUrl == url;
            final bool isChapLiked = _podcastsLikesIds.contains(doc.id);

            return Card(
              color: enCours ? const Color(0xFFA855F7).withOpacity(0.1) : cardColor,
              margin: const EdgeInsets.symmetric(vertical: 6),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                leading: IconButton(icon: Icon(enCours && _isPlaying ? Icons.pause_circle_filled_rounded : Icons.play_circle_filled_rounded, color: const Color(0xFFA855F7), size: 28), onPressed: () { if (url.isNotEmpty) _gererLecture(url, ep); }),
                title: Text(ep['Titre'] ?? 'Sans titre', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: enCours ? const Color(0xFFA855F7) : titleColor)),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(icon: const Icon(Icons.share_rounded, color: Colors.grey, size: 16), onPressed: () => _partagerPodcast(doc.id, ep['Titre'] ?? 'Sans titre')),
                    if (widget.isAdmin) IconButton(icon: const Icon(Icons.settings_rounded, color: Colors.grey, size: 16), onPressed: () => _ouvrirOutilAdmin(docAModifier: doc)),
                    IconButton(icon: Icon(isChapLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded, color: isChapLiked ? Colors.redAccent : Colors.grey, size: 18), onPressed: () => _basculerLike(doc.id)),
                  ],
                ),
              ),
            );
          }).toList(),
          const SizedBox(height: 120), 
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) { if (mounted && !_searchFocusNode.hasFocus) _globalFocusNode.requestFocus(); });
    final Color cardColor = widget.isDarkMode ? const Color(0xFF1E1E1E) : Colors.white;
    final Color barColor = widget.isDarkMode ? const Color(0xFF1A1A1A) : Colors.white;
    final Color searchFieldColor = widget.isDarkMode ? const Color(0xFF2D2D2D) : const Color(0xFFF1F5F9);
    final Color titleColor = widget.isDarkMode ? Colors.white : const Color(0xFF0F172A);
    final Color subTitleColor = widget.isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return KeyboardListener(
      focusNode: _globalFocusNode, onKeyEvent: _gererClavier,
      child: Scaffold(
        body: Stack(
          children: [
            Container(
              decoration: BoxDecoration(gradient: widget.isDarkMode ? const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF1A1A1A), Color(0xFF121212)]) : const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFF4F7F9), Color(0xFFE5EBF0)])),
              child: StreamBuilder<QuerySnapshot>(
                stream: _podcastsStream,
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                  final tousLesDocs = snapshot.data!.docs;
                  _verifierLienDePartage(tousLesDocs);

                  final Set<String> themesUniques = {"Tous"};
                  for (var doc in tousLesDocs) {
                    final d = doc.data() as Map<String, dynamic>;
                    if (d['Theme'] != null) themesUniques.add(d['Theme'].toString().trim());
                  }

                  final listeFiltree = tousLesDocs.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final String titre = (data['Titre'] ?? '').toString();
                    final bool estUnChapitreAMasquer = titre.contains('Partie');
                    final bool correspondRecherche = data['Titre'].toString().toLowerCase().contains(_rechercheTexte.toLowerCase()) || data['Description'].toString().toLowerCase().contains(_rechercheTexte.toLowerCase());
                    final bool correspondCategorie = _categorieSelectionnee == "Tous" || data['Theme'] == _categorieSelectionnee;
                    final bool correspondFavoris = !_afficherUniquementFavoris || _podcastsLikesIds.contains(doc.id);
                    return !estUnChapitreAMasquer && correspondRecherche && correspondCategorie && correspondFavoris;
                  }).toList();

                  bool aDesNouveautes = html.window.localStorage['last_check'] != null && tousLesDocs.isNotEmpty;

                  if (_serieSelectionneeData != null) { return _buildVueAlbumSerie(titleColor, subTitleColor, cardColor); }

                  return CustomScrollView(
                    slivers: [
                      SliverAppBar(
                        floating: true, pinned: true, centerTitle: true, backgroundColor: barColor, elevation: 2,
                        leading: widget.isAdmin 
                          ? IconButton(icon: const Icon(Icons.admin_panel_settings_rounded, color: Color(0xFFA855F7)), onPressed: () => _ouvrirOutilAdmin())
                          : const SizedBox.shrink(),
                        title: RichText(text: const TextSpan(children: [TextSpan(text: "ORKYN' ", style: TextStyle(color: Color(0xFFA855F7), fontWeight: FontWeight.bold, fontSize: 20)), TextSpan(text: "Podcasts", style: TextStyle(color: Color(0xFF0EA5E9), fontSize: 20))])),
                        actions: [
                          Stack(children: [IconButton(icon: Icon(Icons.notifications_rounded, color: aDesNouveautes ? const Color(0xFF0EA5E9) : const Color(0xFF475569)), onPressed: () => _ouvrirNotifications(tousLesDocs)), if (aDesNouveautes) Positioned(top: 10, right: 10, child: Container(width: 9, height: 9, decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle)))]),
                          IconButton(icon: Icon(widget.isDarkMode ? Icons.wb_sunny_rounded : Icons.nightlight_round, color: widget.isDarkMode ? Colors.amber : const Color(0xFF475569)), onPressed: () => widget.onThemeChanged(!widget.isDarkMode)),
                          IconButton(icon: const Icon(Icons.logout_rounded, color: Colors.redAccent), onPressed: () { _audioElement?.pause(); widget.onLogout(); }),
                        ],
                      ),
                      SliverToBoxAdapter(
                        child: Container(
                          color: barColor, padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                          child: Row(
                            children: [
                              Expanded(
                                child: Container(
                                  height: 45, decoration: BoxDecoration(color: searchFieldColor, borderRadius: BorderRadius.circular(12)),
                                  child: TextField(
                                    controller: _searchController, focusNode: _searchFocusNode, style: TextStyle(color: widget.isDarkMode ? Colors.white : Colors.black),
                                    onChanged: (value) => setState(() { _rechercheTexte = value; }),
                                    decoration: InputDecoration(hintText: 'Rechercher...', prefixIcon: const Icon(Icons.search_rounded), suffixIcon: _rechercheTexte.isNotEmpty ? IconButton(icon: const Icon(Icons.clear_rounded), onPressed: () => setState(() { _searchController.clear(); _rechercheTexte = ""; })) : null, border: InputBorder.none, contentPadding: const EdgeInsets.symmetric(vertical: 11)),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              IconButton(icon: Icon(_afficherUniquementFavoris ? Icons.favorite_rounded : Icons.favorite_border_rounded, color: Colors.redAccent), onPressed: () => setState(() { _afficherUniquementFavoris = !_afficherUniquementFavoris; })),
                              Container(
                                height: 45, padding: const EdgeInsets.symmetric(horizontal: 12), decoration: BoxDecoration(color: widget.isDarkMode ? const Color(0xFF2E1A47) : const Color(0xFFF5F3FF), borderRadius: BorderRadius.circular(12)),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: _categorieSelectionnee, dropdownColor: widget.isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
                                    onChanged: (v) { if (v != null) setState(() { _categorieSelectionnee = v; }); },
                                    items: themesUniques.map((t) => DropdownMenuItem(value: t, child: Text(t, style: TextStyle(color: widget.isDarkMode ? Colors.white : Colors.black)))).toList(),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (_categorieSelectionnee == "Tous" && _rechercheTexte.isEmpty && !_afficherUniquementFavoris) ...[
                        const SliverToBoxAdapter(child: Padding(padding: EdgeInsets.only(left: 24.0, top: 24.0, bottom: 12.0), child: Text('✨ Nouveautés / Derniers ajouts', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)))),
                        SliverToBoxAdapter(child: SizedBox(height: 220, child: ListView.builder(scrollDirection: Axis.horizontal, padding: const EdgeInsets.only(left: 24.0), itemCount: listeFiltree.length, itemBuilder: (context, index) => _buildPodcastCardHorizontal(listeFiltree[listeFiltree.length - 1 - index], cardColor, titleColor, subTitleColor, tousLesDocs)))),
                        const SliverToBoxAdapter(child: Padding(padding: EdgeInsets.only(left: 24.0, top: 28.0, bottom: 12.0), child: Text('🔥 Sélection Orkyn\'', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)))),
                        SliverToBoxAdapter(child: SizedBox(height: 220, child: ListView.builder(scrollDirection: Axis.horizontal, padding: const EdgeInsets.only(left: 24.0), itemCount: listeFiltree.length > 3 ? 3 : listeFiltree.length, itemBuilder: (context, index) => _buildPodcastCardHorizontal(listeFiltree[index], cardColor, titleColor, subTitleColor, tousLesDocs)))),
                        const SliverToBoxAdapter(child: SizedBox(height: 120)),
                      ] else ...[
                        SliverList(delegate: SliverChildBuilderDelegate((context, index) => _buildPodcastCardVertical(listeFiltree[index], cardColor, titleColor, subTitleColor, tousLesDocs), childCount: listeFiltree.length)),
                        const SliverToBoxAdapter(child: SizedBox(height: 120)),
                      ]
                    ],
                  );
                },
              ),
            ),
            if (_currentPlayingUrl != null)
              AnimatedPositioned(
                duration: const Duration(milliseconds: 350), bottom: 0, left: 0, right: 0,
                height: _isPlayerExpanded ? MediaQuery.of(context).size.height : 75,
                child: Container(
                  decoration: BoxDecoration(color: widget.isDarkMode ? const Color(0xFF1E1E1E) : Colors.white, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 15, offset: const Offset(0, -4))]),
                  child: _isPlayerExpanded ? _buildFullPlayer(titleColor, subTitleColor) : _buildMiniPlayer(titleColor), 
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniPlayer(Color titleColor) {
    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 4.0, left: 16.0, right: 16.0),
          child: Row(
            children: [
              IconButton(icon: const Icon(Icons.keyboard_arrow_up_rounded, color: Color(0xFF0EA5E9), size: 28), onPressed: () => setState(() => _isPlayerExpanded = true)),
              const SizedBox(width: 8),
              ClipRRect(borderRadius: BorderRadius.circular(6), child: _currentImageUrl.isNotEmpty ? Image.network(_currentImageUrl, width: 40, height: 40, fit: BoxFit.cover, errorBuilder: (_,__,___)=>const Icon(Icons.music_note)) : const Icon(Icons.music_note)),
              const SizedBox(width: 12),
              Expanded(child: Text(_currentTitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: titleColor))),
              Padding(padding: const EdgeInsets.symmetric(horizontal: 12.0), child: Text('${_formaterTemps(_positionActuelle)} / ${_formaterTemps(_dureeTotale)}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
              IconButton(icon: const Icon(Icons.replay_10_rounded), onPressed: () => _changerPosition(_positionActuelle - 10.0)),
              IconButton(icon: Icon(_isPlaying ? Icons.pause_circle_filled_rounded : Icons.play_circle_filled_rounded, size: 38, color: const Color(0xFFA855F7)), onPressed: () => _gererLecture(_currentPlayingUrl!)),
              IconButton(icon: const Icon(Icons.forward_10_rounded), onPressed: () => _changerPosition(_positionActuelle + 10.0)),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () {
                  int indexActuel = _vitessesDisponibles.indexOf(_vitesseActuelle);
                  int prochainIndex = (indexActuel + 1) % _vitessesDisponibles.length;
                  _vitesseSelectionnee(_vitessesDisponibles[prochainIndex]);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: const Color(0xFF1E222B), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white.withOpacity(0.1))),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [Text("${_vitesseActuelle}x", style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)), const SizedBox(width: 2), const Icon(Icons.speed, color: Color(0xFF9D57FF), size: 12)]),
                ),
              ),
            ],
          ),
        ),
        Positioned(
          top: -18, left: 0, right: 0, height: 40,
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 0.0), overlayShape: const RoundSliderOverlayShape(overlayRadius: 0.0), trackHeight: 3.0, activeTrackColor: const Color(0xFFA855F7), inactiveTrackColor: Colors.grey.withOpacity(0.2)),
            child: Slider(min: 0.0, max: _dureeTotale > 0 ? _dureeTotale : 1.0, value: _positionActuelle.clamp(0.0, _dureeTotale > 0 ? _dureeTotale : 1.0), onChanged: (v) => _changerPosition(v)),
          ),
        ),
      ],
    );
  }

  Widget _buildFullPlayer(Color titleColor, Color subTitleColor) {
    return Scaffold(
      backgroundColor: widget.isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
      appBar: AppBar(backgroundColor: Colors.transparent, leading: IconButton(icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 36), onPressed: () => setState(() => _isPlayerExpanded = false)), title: const Text("LECTURE"), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Center(child: Container(width: 200, height: 200, decoration: BoxDecoration(borderRadius: BorderRadius.circular(24), image: DecorationImage(image: NetworkImage(_currentImageUrl.isNotEmpty ? _currentImageUrl : 'https://picsum.photos/id/101/400/400'), fit: BoxFit.cover)))),
            const SizedBox(height: 24),
            Text(_currentTitle, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: titleColor)),
            const SizedBox(height: 24), 
            Slider(activeColor: const Color(0xFFA855F7), value: _positionActuelle.clamp(0.0, _dureeTotale > 0 ? _dureeTotale : 1.0), max: _dureeTotale > 0 ? _dureeTotale : 1.0, onChanged: (v) => _changerPosition(v)),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(_formaterTemps(_positionActuelle)), Text(_formaterTemps(_dureeTotale))]),
            const SizedBox(height: 16),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(color: const Color(0xFFA855F7), borderRadius: BorderRadius.circular(30)),
                    child: Row(
                      mainAxisSize: MainAxisSize.min, 
                      children: _vitessesDisponibles.map((v) {
                        final bool isSelected = _vitesseActuelle == v;
                        return GestureDetector(
                          onTap: () => _vitesseSelectionnee(v),
                          child: AnimatedContainer(duration: const Duration(milliseconds: 200), padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8), decoration: BoxDecoration(color: isSelected ? Colors.white : Colors.transparent, borderRadius: BorderRadius.circular(20)), child: Text("${v}x", style: TextStyle(color: isSelected ? const Color(0xFFA855F7) : Colors.white.withOpacity(0.9), fontSize: 13, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal))),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(icon: const Icon(Icons.replay_10_rounded, size: 36), onPressed: () => _changerPosition(_positionActuelle - 10.0)),
                IconButton(icon: Icon(_isPlaying ? Icons.pause_circle_filled_rounded : Icons.play_circle_filled_rounded, size: 64, color: const Color(0xFFA855F7)), onPressed: () => _gererLecture(_currentPlayingUrl!)),
                IconButton(icon: const Icon(Icons.forward_10_rounded, size: 36), onPressed: () => _changerPosition(_positionActuelle + 10.0)),
              ],
            )
          ],
        ),
      ),
    );
  }
}

class AdminUploadScreen extends StatefulWidget {
  final bool isDarkMode;
  final DocumentSnapshot? podcastDoc;
  const AdminUploadScreen({super.key, required this.isDarkMode, this.podcastDoc});

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
  void initState() {
    super.initState();
    if (widget.podcastDoc != null) {
      final data = widget.podcastDoc!.data() as Map<String, dynamic>;
      _titleController.text = data['Titre'] ?? '';
      _descriptionController.text = data['Description'] ?? '';
      _themeController.text = data['Theme'] ?? '';
      _audioUrlController.text = data['audio_url'] ?? '';
      _imageUrlController.text = data['image_url'] ?? '';
    }
  }

  @override
  void dispose() {
    _titleController.dispose(); 
    _descriptionController.dispose(); 
    _themeController.dispose(); 
    _audioUrlController.dispose(); 
    _imageUrlController.dispose();
    super.dispose();
  }

  void _sauvegarder() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() { _enCoursEnvoi = true; });

    final data = {
      'Titre': _titleController.text.trim(),
      'Description': _descriptionController.text.trim(),
      'Theme': _themeController.text.trim().isEmpty ? 'Général' : _themeController.text.trim(),
      'audio_url': _audioUrlController.text.trim(),
      'image_url': _imageUrlController.text.trim().isEmpty ? 'https://picsum.photos/id/101/400/400' : _imageUrlController.text.trim(),
      'date_ajout': FieldValue.serverTimestamp(),
    };

    try {
      if (widget.podcastDoc == null) {
        await FirebaseFirestore.instance.collection('podcasts').add(data);
      } else {
        await FirebaseFirestore.instance.collection('podcasts').doc(widget.podcastDoc!.id).update(data);
      }
      
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erreur lors de la sauvegarde : $e"), backgroundColor: Colors.red),
        );
      }
    } finally { 
      if (mounted) {
        setState(() { _enCoursEnvoi = false; }); 
      }
    }
  }

  void _supprimer() async {
    bool? confirm = await showDialog(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: widget.isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        title: const Text("🗑️ Supprimer ?"),
        content: const Text("Supprimer définitivement ce podcast ?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text("Annuler")),
          ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white), onPressed: () => Navigator.pop(c, true), child: const Text("Supprimer")),
        ],
      ),
    );
    if (confirm == true) {
      await FirebaseFirestore.instance.collection('podcasts').doc(widget.podcastDoc!.id).delete();
      if (mounted) { Navigator.pop(context); }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.podcastDoc == null ? "Ajouter" : "Éditer")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(controller: _titleController, decoration: const InputDecoration(labelText: "Titre *"), validator: (v) => v!.isEmpty ? "Requis" : null),
              const SizedBox(height: 16),
              TextFormField(controller: _descriptionController, maxLines: 3, decoration: const InputDecoration(labelText: "Description *"), validator: (v) => v!.isEmpty ? "Requis" : null),
              const SizedBox(height: 16),
              TextFormField(controller: _themeController, decoration: const InputDecoration(labelText: "Thème")),
              const SizedBox(height: 16),
              TextFormField(controller: _audioUrlController, decoration: const InputDecoration(labelText: "URL Audio .mp3 *"), validator: (v) => v!.isEmpty ? "Requis" : null),
              const SizedBox(height: 16),
              TextFormField(controller: _imageUrlController, decoration: const InputDecoration(labelText: "URL Image")),
              const SizedBox(height: 32),
              if (_enCoursEnvoi) const Center(child: CircularProgressIndicator()) else ...[
                ElevatedButton(onPressed: _sauvegarder, child: const Text("Sauvegarder")),
                if (widget.podcastDoc != null) ...[const SizedBox(height: 16), ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white), onPressed: _supprimer, child: const Text("Supprimer ce podcast"))]
              ]
            ],
          ),
        ),
      ),
    );
  }
}