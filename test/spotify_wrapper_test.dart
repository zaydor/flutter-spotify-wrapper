import 'package:flutter_test/flutter_test.dart';

import 'package:spotify_wrapper/spotify_wrapper.dart';

void main() {
  test('adds one to input values', () {
    final calculator = Calculator();
    expect(calculator.addOne(2), 3);
    expect(calculator.addOne(-7), -6);
    expect(calculator.addOne(0), 1);
  });

  // test('checks if spotify wrapper is getting a good response', () async {
  //   final spotify = SpotifyWrapper();
  //   final result = await spotify.isSpotifyApiWorking();
  //   expect(result, true);
  // });

  // test('checks if spotify wrapper can get a token', () async {
  //   final spotify = SpotifyWrapper();
  //   final result = await spotify.getToken();
  //   expect(result, isNotNull);
  // });
  // test(
  //   'checks if spotify wrapper can get a token with a valid client id',
  //   () async {
  //     final spotify = SpotifyWrapper();
  //     final result = await spotify.getToken(clientId: 'valid_client_id');
  //     expect(result, isNotNull);
  //   },
  // );
  // test('checks if spotify wrapper can get song data', () async {
  //   final spotify = SpotifyWrapper();
  //   final result = await spotify.getSongData('song_id');
  //   expect(result, isNotNull);
  // });
  // test('checks if spotify wrapper can get playlist data', () async {
  //   final spotify = SpotifyWrapper();
  //   final result = await spotify.getPlaylistData('playlist_id');
  //   expect(result, isNotNull);
  // });
  // test('checks if spotify wrapper can get album data', () async {
  //   final spotify = SpotifyWrapper();
  //   final result = await spotify.getAlbumData('album_id');
  //   expect(result, isNotNull);
  // });
  // test('checks if spotify wrapper can get artist data', () async {
  //   final spotify = SpotifyWrapper();
  //   final result = await spotify.getArtistData('artist_id');
  //   expect(result, isNotNull);
  // });
  // test('checks if spotify wrapper can get user data', () async {
  //   final spotify = SpotifyWrapper();
  //   final result = await spotify.getUserData('user_id');
  //   expect(result, isNotNull);
  // });
}
