# Senior Listening App

시니어를 위한 따뜻한 경청 앱 Flutter 프로젝트입니다.

## 핵심 컨셉
- 큰 글씨와 단순한 버튼
- 느린 반응으로 부담을 줄이는 대화 흐름
- 따뜻한 베이지/올리브/살구 톤 UI
- 음성 입력, 공감형 AI 응답, 마음 기록

## 포함된 화면
- 홈 화면
- 대화 화면
- 내 이야기 보기
- 마음 쉬기

## 기술 스택
- Flutter
- OpenAI Chat Completions API
- speech_to_text
- flutter_tts
- shared_preferences

## 시작 방법

### 1) 플랫폼 폴더 생성
이 저장소는 GitHub 업로드용으로 가볍게 구성되어 있습니다.
Flutter가 설치된 환경에서 아래 명령으로 플랫폼 폴더를 생성하세요.

```bash
flutter create .
```

### 2) 패키지 설치
```bash
flutter pub get
```

### 3) 앱 실행
OpenAI API Key를 `--dart-define` 로 주입하세요.

```bash
flutter run --dart-define=OPENAI_API_KEY=YOUR_OPENAI_API_KEY
```

## iOS / Android 권한
음성 입력을 사용할 경우 플랫폼별 마이크 권한 설정이 필요합니다.
`flutter create .` 이후 아래 예시처럼 추가하세요.

### iOS (`ios/Runner/Info.plist`)
```xml
<key>NSMicrophoneUsageDescription</key>
<string>마음을 이야기할 수 있도록 마이크 권한이 필요합니다.</string>
<key>NSSpeechRecognitionUsageDescription</key>
<string>음성을 글로 바꾸기 위해 음성 인식 권한이 필요합니다.</string>
```

### Android (`android/app/src/main/AndroidManifest.xml`)
```xml
<uses-permission android:name="android.permission.RECORD_AUDIO" />
```

## GitHub 업로드 순서
```bash
git init
git add .
git commit -m "Initial commit: senior listening app"
git branch -M main
git remote add origin YOUR_GITHUB_REPO_URL
git push -u origin main
```

## OpenAI 시스템 프롬프트 방향
- 조언보다 경청 우선
- 해결보다 공감 우선
- 짧고 따뜻하게 응답
- 3~5초 지연으로 서두르지 않는 느낌 유지

## 참고
- 실제 배포 전에는 API Key를 앱에 직접 하드코딩하지 마세요.
- 대화 저장은 현재 local storage(shared_preferences) 기반입니다.
