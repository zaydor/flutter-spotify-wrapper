import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:uni_links/uni_links.dart';

class SpotifyWrapper {
  String clientId;
  String clientSecret;
  String uriScheme;
  String callbackUrl;
  String accessToken;
  String refreshToken;
  DateTime accessTokenExpiry;
  List<String> scopes;
  final http.Client _httpClient;

  factory SpotifyWrapper({
    required String clientId,
    required String clientSecret,
    required String uriScheme,
    required String callbackUrl,
    String? accessToken,
    String? refreshToken,
    List<String>? scopes,
    DateTime? accessTokenExpiry,
    http.Client? httpClient,
  }) {
    return SpotifyWrapper._internal(
      clientId: clientId,
      clientSecret: clientSecret,
      accessTokenExpiry: accessTokenExpiry ?? DateTime.now(),
      uriScheme: uriScheme,
      callbackUrl: callbackUrl,
      accessToken: accessToken ?? '',
      refreshToken: refreshToken ?? '',
      scopes:
          scopes ??
          [
            'user-read-private',
            'user-read-email',
            'user-read-playback-state',
            'user-modify-playback-state',
          ],
      httpClient: httpClient,
    );
  }
  SpotifyWrapper._internal({
    required this.clientId,
    required this.clientSecret,
    required this.accessTokenExpiry,
    required this.uriScheme,
    required this.callbackUrl,
    required this.accessToken,
    required this.refreshToken,
    required this.scopes,
    http.Client? httpClient,
  }) : _httpClient = httpClient ?? http.Client();

  void initializeSpotifyWrapper() {
    _initializeUriListener();
  }

  void _initializeUriListener() {
    uriLinkStream.listen(
      (Uri? uri) {
        if (uri == null) {
          // Handle the case where the URI is null
          print('Received null URI');
          return;
        }

        if (uri.scheme != uriScheme) {
          // Handle the case where the URI scheme does not match
          print('Received URI with unexpected scheme: ${uri.scheme}');
          return;
        }

        final code = uri.queryParameters['code'];

        if (code == null) {
          // Handle the case where the code is not present in the URI
          print('Received URI without code parameter');
          return;
        }

        _exchangeCodeForToken(code);
      },
      onError: (err) {
        // Handle errors from the URI listener
        print('Error listening to URI links: $err');
      },
    );
  }

  Future<bool> isAuthenticated() async {
    return accessToken.isNotEmpty && refreshToken.isNotEmpty;
  }

  Future<void> _exchangeCodeForToken(String code) async {
    final response = await _httpClient.post(
      Uri.parse('https://accounts.spotify.com/api/token'),
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
        'Authorization':
            'Basic ${base64Encode(utf8.encode('$clientId:$clientSecret'))}',
      },
      body: {
        'grant_type': 'authorization_code',
        'code': code,
        'redirect_uri': callbackUrl,
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      accessToken = data['access_token'];
      refreshToken = data['refresh_token'];
      accessTokenExpiry = DateTime.now().add(
        Duration(seconds: data['expires_in']),
      );
      print('Access token obtained successfully');
    } else {
      print(
        'Failed to exchange code for token: ${response.statusCode} ${response.body}',
      );
      throw Exception('Failed to exhange code for token');
    }
  }

  Future<void> requestSpotifyAuthorization() async {
    Uri uri = Uri.parse(
      'https://accounts.spotify.com/authorize?response_type=code&client_id=$clientId&scope=${Uri.encodeComponent(scopes.join(' '))}&redirect_uri=${Uri.encodeComponent(callbackUrl)}',
    );

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      print('Could not launch Spotify authorization URL: $uri');
      throw Exception('Could not launch Spotify authorization URL');
    }
  }

  Future<void> requestSpotifyCredentials() async {
    final response = await _httpClient.post(
      Uri.parse('https://accounts.spotify.com/api/token'),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {
        'grant_type': 'client_credentials',
        'client_id': clientId,
        'client_secret': clientSecret,
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      accessToken = data['access_token'];
      accessTokenExpiry = DateTime.now().add(
        Duration(seconds: data['expires_in']),
      );
    } else {
      print(
        'Failed to request Spotify credentials: ${response.statusCode} ${response.body}',
      );
      throw Exception('Failed to request Spotify credentials');
    }
  }

  bool _isTokenValid() {
    return accessToken.isNotEmpty && DateTime.now().isBefore(accessTokenExpiry);
  }

  Future<void> _ensureValidToken() async {
    if (_isTokenValid()) {
      return;
    }
    if (refreshToken.isNotEmpty) {
      await requestSpotifyCredentials();
    } else {
      await requestSpotifyAuthorization();
    }
  }

  Future<dynamic> getPlaylist(String playlistId) async {
    await _ensureValidToken();

    final response = await _httpClient.get(
      Uri.parse('https:/api.spotify.com/v1/playlists/$playlistId'),
      headers: {'Authorization': 'Bearer $accessToken'},
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data;
    } else {
      print('Failed to get playlist: ${response.statusCode} ${response.body}');
      throw Exception('Failed to get playlist');
    }
  }

  Future<dynamic> getSongsFromPlaylist(
    String playlistId,
    int offset,
    int limit,
  ) async {
    await _ensureValidToken();

    final response = await _httpClient.get(
      Uri.parse(
        'https://api.spotify.com/v1/playlists/$playlistId/tracks?offset=$offset&limit=$limit',
      ),
      headers: {'Authorization': 'Bearer $accessToken'},
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['items'];
    } else {
      print(
        'Failed to get songs from playlist: ${response.statusCode} ${response.body}',
      );
      throw Exception('Failed to get songs from playlist');
    }
  }

  Future<bool> playSongs(List<String> songUris) async {
    await _ensureValidToken();

    final response = await _httpClient.put(
      Uri.parse('https://api.spotify.com/v1/me/player/play'),
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'uris': songUris}),
    );

    if (response.statusCode == 204) {
      return true;
    } else {
      print('Failed to play songs: ${response.statusCode} ${response.body}');
      throw Exception('Failed to play songs');
    }
  }

  Future<List<dynamic>> getAvailableDevices() async {
    await _ensureValidToken();

    final response = await _httpClient.get(
      Uri.parse('https://api.spotify.com/v1/me/player/devices'),
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['devices'];
    } else {
      print(
        'Failed to get available devices: ${response.statusCode} ${response.body}',
      );
      throw Exception('Failed to get available devices');
    }
  }

  Future<bool> transferPlayback(String deviceId, bool shouldPlay) async {
    await _ensureValidToken();

    final response = await _httpClient.put(
      Uri.parse('https://api.spotify.com/v1/me/player'),
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'device_ids': [deviceId],
        'play': shouldPlay,
      }),
    );

    if (response.statusCode == 204) {
      return true;
    } else {
      print(
        'Failed to transfer playback: ${response.statusCode} ${response.body}',
      );
      throw Exception('Failed to transfer playback');
    }
  }
}
