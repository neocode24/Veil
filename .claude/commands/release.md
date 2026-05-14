# Veil Release

Veil macOS 앱의 전체 릴리스를 자동으로 실행하고 완료 후 결과를 보고한다.

## 사용법

```
/release          # 현재 버전 확인 후 새 버전 한 번만 묻고 자동 진행
/release 0.4.1    # 버전 지정 시 바로 자동 진행
```

**중요: 버전 결정 이후 모든 단계는 중간 확인 없이 자동으로 실행된다. 완료 후 최종 보고만 출력한다.**

---

## 실행 순서

### 1. 현재 상태 확인

```bash
grep 'MARKETING_VERSION' Veil/project.yml | grep -o '"[^"]*"' | tr -d '"'
grep '^VERSION' Makefile | cut -d' ' -f3
git describe --tags --abbrev=0 2>/dev/null
git status --short
```

- 워킹 디렉토리가 dirty하면 어떤 파일인지 출력하고 중단한다 (의도치 않은 파일 포함 방지).
- 두 파일의 버전이 이미 일치하고 해당 태그가 없는 경우 → 버전 업데이트 단계를 건너뛴다.

### 2. 버전 결정

- 인자로 버전이 주어진 경우 바로 사용한다.
- 없으면 현재 버전을 보여주고 새 버전을 **한 번만** 묻는다.
- semver `X.Y.Z` 형식이 아니면 재입력 요청.
- **이후 모든 단계는 자동 진행.**

### 3. 버전 파일 업데이트

이미 목표 버전과 일치하면 건너뛴다. 아니면 Edit 도구로 수정:

- `Veil/project.yml` → `MARKETING_VERSION: "X.Y.Z"`
- `Makefile` → `VERSION := X.Y.Z`

### 4. 빌드 검증

```bash
make setup
make build
```

빌드 실패 시 즉시 중단하고 오류 로그를 출력한다.

### 5. 릴리스 노트 자동 생성

```bash
PREV_TAG=$(git describe --tags --abbrev=0)
git log ${PREV_TAG}..HEAD --pretty=format:"%s (%h)" --no-merges
```

conventional commits 기준으로 분류. 섹션에 해당 커밋이 없으면 생략:

```markdown
## 새 기능
- feat: 커밋 내용 (hash)

## 버그 수정
- fix: 커밋 내용 (hash)

## 개선
- refactor:, perf: 커밋 내용 (hash)

## 문서
- docs: 커밋 내용 (hash)

## 기타
- chore:, ci:, style: 커밋 내용 (hash)

---

**설치**
\`\`\`bash
brew upgrade --cask --no-quarantine veil
# 또는 신규 설치
brew tap neocode24/tap
brew install --cask --no-quarantine veil
\`\`\`

**전체 변경사항**: https://github.com/neocode24/veil/compare/PREV_TAG...vNEW
```

### 6. Git 커밋 + 태그

버전 파일을 업데이트한 경우에만 커밋. 태그는 항상 생성:

```bash
# 버전 파일 변경이 있을 때만
git add Veil/project.yml Makefile Veil/Veil.xcodeproj/project.pbxproj
git commit -m "chore: 버전 X.Y.Z으로 bump"

git tag vX.Y.Z
```

### 7. Push

```bash
git push origin main
git push origin vX.Y.Z
```

push 실패 시 중단하고 수동 명령어를 안내한다.

### 8. GitHub Actions 폴링

태그 push 후 최대 10분간 10초 간격으로 상태를 확인한다. 진행 중에는 사용자에게 아무것도 출력하지 않는다.

```bash
# run ID 확보 (push 후 약 5초 대기)
gh run list --repo neocode24/veil --limit 1 --json databaseId,status,conclusion

# 완료까지 반복 확인
gh run view RUN_ID --repo neocode24/veil --json status,conclusion,jobs
```

- 10분 초과 시: 폴링 중단하고 run URL을 최종 보고에 포함.
- failure 시: 실패한 job 이름과 로그 URL을 최종 보고에 포함.

### 9. brew-tap 확인

Actions 성공 후 실행:

```bash
gh api "repos/neocode24/homebrew-tap/commits?path=Casks/veil.rb&per_page=1" \
  --jq '.[0] | {sha: .sha[:7], message: .commit.message, date: .commit.author.date}'

gh api repos/neocode24/homebrew-tap/contents/Casks/veil.rb \
  --jq '.content' | base64 -d | grep -E 'version|sha256|url'
```

### 10. 최종 보고

모든 단계 완료 후 한 번에 출력:

```
릴리스 완료: v0.4.1

버전 업데이트  : 0.4.0 → 0.4.1
GitHub Release : https://github.com/neocode24/veil/releases/tag/v0.4.1
Actions        : success (소요: 3분 12초)
brew-tap       : Casks/veil.rb 업데이트 확인 (커밋 abc1234, 버전 0.4.1)

brew upgrade --cask --no-quarantine veil 로 업데이트 가능
```

---

## 오류 처리

| 상황 | 대응 |
|------|------|
| 워킹 디렉토리 dirty | 중단, 파일 목록 출력 |
| 빌드 실패 | 중단, 오류 로그 출력 |
| push 실패 | 중단, 수동 명령어 안내 |
| Actions 10분 초과 | 중단 없이 run URL만 보고 |
| Actions 실패 | 실패 job + 로그 URL 보고 |
| brew-tap 미반영 | 경고만, Actions 로그 URL 포함 |
