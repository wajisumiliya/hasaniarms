# Android Build

Flutter is required to build the Android APK.

## Local Windows build

From the project root:

```powershell
flutter pub get
flutter build apk --debug --dart-define=API_BASE_URL=http://10.0.2.2:5000/api
```

For a physical Android phone on the same LAN, replace `10.0.2.2` with the Windows PC LAN IP, for example:

```text
http://192.168.1.20:5000/api
```

The Node backend must listen on an interface reachable by the phone. If necessary, configure the server to listen on `0.0.0.0` and allow TCP 5000 through Windows Firewall.

## GitHub Actions

The included workflow builds a debug APK automatically.

It does not contain ARMS credentials. ARMS credentials belong only in the backend `.env` on the server.
