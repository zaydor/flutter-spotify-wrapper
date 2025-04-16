import 'package:flutter_test/flutter_test.dart';
import 'package:spotify_wrapper/spotify_wrapper.dart';
import 'package:mocktail/mocktail.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';
import 'package:http/http.dart' as http;
import 'secrets.dart';

class MockUrlLauncher extends Mock
    with MockPlatformInterfaceMixin
    implements UrlLauncherPlatform {}

class MockHttpClient extends Mock implements http.Client {}

class UriFake extends Fake implements Uri {}

void main() {
  late SpotifyWrapper spotify;
  late MockUrlLauncher mockUrlLauncher;
  late MockHttpClient mockHttpClient;

  MockUrlLauncher setupMockUrlLauncher() {
    final mock = MockUrlLauncher();
    registerFallbackValue(const LaunchOptions());
    when(() => mock.launchUrl(any(), any())).thenAnswer((_) async => true);
    when(() => mock.canLaunch(any())).thenAnswer((_) async => true);
    return mock;
  }

  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    registerFallbackValue(UriFake());
    final mock = setupMockUrlLauncher();
    UrlLauncherPlatform.instance = mock;

    mockHttpClient = MockHttpClient();
    spotify = SpotifyWrapper(
      clientId: Secrets.spotifyClientId,
      clientSecret: Secrets.spotifyClientSecret,
      uriScheme: 'wendycompanion',
      callbackUrl: 'wendycompanion://callback',
      httpClient: mockHttpClient,
    );
    spotify.initializeSpotifyWrapper();
  });

  test('initializeSpotifyWrapper sets up URI listener', () {
    expect(() => spotify.initializeSpotifyWrapper(), returnsNormally);
  });

  test(
    'isAuthenticated returns true when access and refresh tokens are set',
    () async {
      spotify.accessToken = 'test_access_token';
      spotify.refreshToken = 'test_refresh_token';
      final result = await spotify.isAuthenticated();
      expect(result, true);
    },
  );

  test('requestSpotifyAuthorization launches authorization URL', () async {
    expect(() => spotify.requestSpotifyAuthorization(), returnsNormally);
  });

  test('requestSpotifyCredentials fetches and sets access token', () async {
    when(
      () => mockHttpClient.post(
        any(),
        headers: any(named: 'headers'),
        body: any(named: 'body'),
      ),
    ).thenAnswer(
      (_) async => http.Response(
        '{"access_token": "test_token", "expires_in": 3600}',
        200,
      ),
    );

    await spotify.requestSpotifyCredentials();
    expect(spotify.accessToken, 'test_token');
    expect(spotify.accessTokenExpiry.isAfter(DateTime.now()), true);
  });

  test('getPlaylist fetches playlist data', () async {
    when(
      () => mockHttpClient.get(any(), headers: any(named: 'headers')),
    ).thenAnswer(
      (_) async => http.Response(
        '{"id": "test_playlist_id", "name": "Test Playlist"}',
        200,
      ),
    );

    final playlist = await spotify.getPlaylist('test_playlist_id');
    expect(playlist['id'], 'test_playlist_id');
    expect(playlist['name'], 'Test Playlist');
  });

  test('getSongsFromPlaylist fetches songs from playlist', () async {
    when(
      () => mockHttpClient.get(any(), headers: any(named: 'headers')),
    ).thenAnswer(
      (_) async => http.Response(
        '{"items": [{"track": {"id": "test_song_id", "name": "Test Song"}}]}',
        200,
      ),
    );

    final songs = await spotify.getSongsFromPlaylist('test_playlist_id', 0, 10);
    expect(songs, isNotEmpty);
    expect(songs[0]['track']['id'], 'test_song_id');
  });

  test('playSongs sends play request to Spotify API', () async {
    when(
      () => mockHttpClient.put(
        any(),
        headers: any(named: 'headers'),
        body: any(named: 'body'),
      ),
    ).thenAnswer((_) async => http.Response('', 204));

    final result = await spotify.playSongs(['spotify:track:test_song_id']);
    expect(result, true);
  });

  test('getAvailableDevices fetches available devices', () async {
    when(
      () => mockHttpClient.get(any(), headers: any(named: 'headers')),
    ).thenAnswer(
      (_) async => http.Response(
        '{"devices": [{"id": "test_device_id", "name": "Test Device"}]}',
        200,
      ),
    );

    final devices = await spotify.getAvailableDevices();
    expect(devices, isNotEmpty);
    expect(devices[0]['id'], 'test_device_id');
  });

  test('transferPlayback sends transfer playback request', () async {
    when(
      () => mockHttpClient.put(
        any(),
        headers: any(named: 'headers'),
        body: any(named: 'body'),
      ),
    ).thenAnswer((_) async => http.Response('', 204));

    final result = await spotify.transferPlayback('test_device_id', true);
    expect(result, true);
  });
}
