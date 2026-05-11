# Veil

macOS menu bar app - fullscreen 감지 시 다른 모니터를 blanking

## 버전업 체크리스트

새 버전 릴리스 시 아래 파일들의 버전을 함께 수정해야 함:

| 파일 | 필드 | 비고 |
|------|------|------|
| `Veil/project.yml` | `MARKETING_VERSION` | xcodegen 소스 |
| `Makefile` | `VERSION` | 로컬 빌드/패키징 |

`Veil/Veil.xcodeproj/project.pbxproj`는 xcodegen이 자동 생성하므로 직접 수정 불필요.

## 빌드 & 실행

```bash
make run      # 빌드 + 실행
make build    # Release 빌드만
make debug    # Debug 빌드
make clean    # 빌드 산출물 삭제
```

## 릴리스

```bash
# 1. 위 파일들 버전 수정
# 2. 커밋 + 태그
git commit -m "chore: 버전 x.y.z으로 bump"
git tag vx.y.z
# 3. push (태그 포함)
git push && git push origin vx.y.z
```

태그 push 시 GitHub Actions가 자동으로:
- Release 빌드 + zip 패키징
- GitHub Release 생성
- `homebrew-tap` repo의 `Casks/veil.rb` 업데이트 (SSH deploy key)

## 아키텍처

- `StatusBarController` - 메뉴바 아이템 + NSPanel popover
- `MenuBarView` - popover SwiftUI 콘텐츠
- `ExcludedAppsView` - 제외 앱 관리
- `AppState` - @Observable 전역 상태
- `DisplayOverlayManager` - 모니터 blanking 오버레이
- `FullscreenMonitor` / `FullscreenDetector` - fullscreen 앱 감지
- `MediaAppDetector` - 제외 앱 목록 관리 (UserDefaults)
- `DS` - 디자인 시스템 토큰
