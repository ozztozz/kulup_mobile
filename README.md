# kulup_mobile

Flutter client for the Django backend in this workspace.

## API endpoints used

- `/api/auth/token/`
- `/api/auth/token/refresh/`
- `/api/auth/me/`
- `/api/teams/`
- `/api/trainings/`
- `/api/payments/`
- `/api/questionnaires/active/`

## Run in development

1. Start Django server:

```powershell
cd c:/Users/USER/Desktop/kulup/kulup
c:/Users/USER/Desktop/kulup/my_env/Scripts/python.exe manage.py runserver
```

This project defaults `runserver` to `0.0.0.0:8000`, so Android emulators and devices can reach the local API.

2. Run Flutter app (Android emulator):

```powershell
cd c:/Users/USER/Desktop/kulup/kulup_mobile
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000
```

3. Run Flutter app (Windows desktop, local Django on same machine):

```powershell
cd c:/Users/USER/Desktop/kulup/kulup_mobile
flutter run
```

4. Run Flutter app (real device in same Wi-Fi):

```powershell
flutter run --dart-define=API_BASE_URL=http://YOUR_PC_LOCAL_IP:8000
```

## Notes

- JWT tokens are stored securely via `flutter_secure_storage`.
- Access token refresh is handled automatically by Dio interceptor.
- Android manifest enables cleartext traffic for local HTTP development.
