# path-live

A mobile app to keep track of live departure times of
[PATH](https://www.panynj.gov/path/en/index.html) trains. Built using
[Flutter](https://flutter.dev/).

> Grab the latest [release](https://github.com/nikhilweee/path-live/releases) to
> try it out!

# Features

- Live departure times for all PATH stations
- Filter to view only selected stations
- Automatically detects your nearest station (with location access)
- Stay updated with currently active service alerts

![alt text](https://i.imgur.com/ldZ6Wvm.png)

# Development

Build an APK for a specific target platform (say ARM64)

```console
flutter build apk --target-platform android-arm64
```

Install the built APK to a connected device

```
adb install build/app/outputs/flutter-apk/app-release.apk
```
