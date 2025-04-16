# SpotifyWrapper

SpotifyWrapper is a Dart package that provides a convenient interface for interacting with the Spotify Web API. It allows you to authenticate users, fetch playlists, play songs, and manage playback devices.

## Prerequisites

To use SpotifyWrapper, you need:

1. A Spotify Developer account.
2. A registered application in the [Spotify Developer Dashboard](https://developer.spotify.com/dashboard/).
3. The following credentials from your Spotify app:
   - Client ID
   - Client Secret
   - Redirect URI (e.g., `yourapp://callback`)

## Installation

Add the following dependencies to your `pubspec.yaml` file:

```yaml
dependencies:
  http: ^0.15.0
  url_launcher: ^6.0.0
  uni_links: ^0.5.0
  mocktail: ^0.3.0 # For testing
```

Run `flutter pub get` to install the dependencies.

## Usage

### Initialize SpotifyWrapper

```dart
import 'package:spotify_wrapper/spotify_wrapper.dart';

final spotify = SpotifyWrapper(
  clientId: 'your-client-id',
  clientSecret: 'your-client-secret',
  uriScheme: 'yourapp',
  callbackUrl: 'yourapp://callback',
);

spotify.initializeSpotifyWrapper();
```

### Authenticate User

```dart
await spotify.requestSpotifyAuthorization();
```

### Fetch a Playlist

```dart
final playlist = await spotify.getPlaylist('playlist-id');
print(playlist);
```

### Play Songs

```dart
await spotify.playSongs(['spotify:track:track-id']);
```

### Get Available Devices

```dart
final devices = await spotify.getAvailableDevices();
print(devices);
```

### Transfer Playback

```dart
await spotify.transferPlayback('device-id', true);
```

## Running Tests

To run the tests for SpotifyWrapper, use the following command:

```bash
flutter test
```

Ensure that you have the `mocktail` package installed for mocking dependencies during tests.