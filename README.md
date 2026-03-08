# KnockKnock iOS

KnockKnock의 iPhone 앱과 Apple Watch 앱을 포함한 Xcode 프로젝트 저장소다.

## 구성

- `knockknock-ios.xcodeproj`: iPhone + Watch 앱 프로젝트
- `knockknock-ios/`: iPhone 앱 소스
- `knockknock-watch Watch App/`: watchOS 앱 소스
- `knockknock-iosTests/`: iPhone 단위 테스트

## 시작

1. Xcode에서 `knockknock-ios.xcodeproj`를 연다.
2. Signing & Capabilities에서 각 타깃의 Team과 Bundle Identifier를 자신의 계정에 맞게 바꾼다.
3. Xcode가 `socket.io-client-swift` 패키지를 자동으로 받지 않으면 `File > Add Package Dependencies...`에서 `https://github.com/socketio/socket.io-client-swift`를 `Up to Next Major` `16.0.0`으로 추가한다.
4. `Config/knockknock-ios-Info.plist`의 `WS_BASE_URL`과 `TRANSIT_API_KEY`를 개발 환경에 맞게 수정한다.
5. 실제 기기에서 Bluetooth, Location, WatchConnectivity 동작을 확인한다.

## 주의

- `TRANSIT_API_KEY`가 비어 있으면 정류장 검색 API는 빈 결과를 반환한다.
- WebSocket 주소 기본값은 `http://localhost:3000`이다.
- Watch 앱은 `WatchConnectivity`로 iPhone 앱과 통신한다.
