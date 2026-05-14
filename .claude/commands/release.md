# Veil Release

Veil macOS 앱의 전체 릴리스 워크플로우를 실행한다.

## 사용법

```
/release [version]
/release 0.4.1
```

버전을 인자로 생략하면 현재 버전을 보여주고 새 버전을 물어본다.

---

## Step 1: 현재 상태 확인

```bash
# 현재 버전 읽기
grep 'MARKETING_VERSION' Veil/project.yml | grep -o '"[^"]*"' | tr -d '"'
grep '^VERSION' Makefile | cut -d' ' -f3

# 최근 태그
git describe --tags --abbrev=0

# 워킹 디렉토리 상태 확인
git status --short
```

워킹 디렉토리에 커밋되지 않은 변경사항이 있으면 릴리스를 진행할지 사용자에게 확인한다.

---

## Step 2: 버전 결정

인자로 버전이 주어지면 그것을 사용한다. 없으면 현재 버전을 보여주고 새 버전을 묻는다.

semver 형식(`X.Y.Z`) 검증:
- `X.Y.Z` 형식이 아니면 재입력 요청
- 현재 버전보다 낮으면 경고 후 확인

버전 타입 판단 (릴리스 노트 생성 시 참고):
- major/minor 변경 → 새 기능 포함 릴리스
- patch 변경 → 버그 수정 릴리스

---

## Step 3: 버전 파일 업데이트

Edit 도구로 두 파일을 수정한다:

**`Veil/project.yml`**:
```
MARKETING_VERSION: "OLD" → MARKETING_VERSION: "NEW"
```

**`Makefile`**:
```
VERSION := OLD → VERSION := NEW
```

수정 후 두 파일의 버전이 일치하는지 확인한다.

---

## Step 4: 빌드 검증

```bash
make setup   # xcodegen으로 project.pbxproj 재생성
make build   # Release 빌드
```

빌드 실패 시 즉시 중단하고 오류를 보고한다. 버전 파일 변경을 되돌리지는 않는다(사용자가 판단).

---

## Step 5: 릴리스 노트 생성

```bash
PREV_TAG=$(git describe --tags --abbrev=0)
git log ${PREV_TAG}..HEAD --pretty=format:"%s (%h)" --no-merges
```

커밋을 conventional commits 기준으로 분류해 한글 릴리스 노트를 작성한다:

```markdown
## 새 기능
- (feat: 커밋들)

## 버그 수정
- (fix: 커밋들)

## 개선
- (refactor:, perf: 커밋들)

## 문서
- (docs: 커밋들)

## 기타
- (chore:, ci:, style: 커밋들)

---

**설치**
\`\`\`bash
brew upgrade --cask veil
# 또는 신규 설치
brew tap neocode24/tap
brew install --cask --no-quarantine veil
\`\`\`

**전체 변경사항**: https://github.com/neocode24/veil/compare/PREV_TAG...vNEW_VERSION
```

분류할 커밋이 없는 섹션은 생략한다.

생성된 릴리스 노트를 사용자에게 보여주고, 수정이 필요한지 확인한다. "수정" 요청 시 사용자가 원하는 내용을 받아 반영한다.

---

## Step 6: Git 커밋 + 태그

```bash
git add Veil/project.yml Makefile Veil/Veil.xcodeproj/project.pbxproj
git commit -m "chore: 버전 X.Y.Z으로 bump"
git tag vX.Y.Z
```

---

## Step 7: Push

```bash
git push origin main
git push origin vX.Y.Z
```

---

## Step 8: GitHub Actions 모니터링

태그 push 직후 워크플로우가 트리거된다. 완료될 때까지 상태를 폴링한다.

```bash
# 최신 run 상태 확인 (10초 간격, 최대 10분)
gh run list --repo neocode24/veil --limit 3
gh run view RUN_ID --repo neocode24/veil
```

상태를 단계별로 보고한다:
- `queued` → 대기 중
- `in_progress` → 빌드/패키징 진행 중
- `completed / success` → 성공
- `completed / failure` → 실패 (로그 URL 제공)

Actions 워크플로우가 하는 일:
1. Release 빌드 + zip 패키징
2. GitHub Release 생성
3. `homebrew-tap` repo의 `Casks/veil.rb` 업데이트

---

## Step 9: brew-tap 업데이트 확인

Actions 성공 후 homebrew-tap 변경을 확인한다:

```bash
# veil.rb의 최신 커밋 확인
gh api repos/neocode24/homebrew-tap/commits?path=Casks/veil.rb&per_page=1 \
  --jq '.[0] | {sha: .sha[:7], message: .commit.message, date: .commit.author.date}'

# veil.rb 내용에서 버전과 sha256 확인
gh api repos/neocode24/homebrew-tap/contents/Casks/veil.rb \
  --jq '.content' | base64 -d | grep -E 'version|sha256|url'
```

새 버전(`vX.Y.Z`)이 반영됐는지 확인 후 결과를 보고한다.

---

## Step 10: 최종 보고

릴리스 완료 후 요약을 출력한다:

```
릴리스 완료: vX.Y.Z

GitHub Release : https://github.com/neocode24/veil/releases/tag/vX.Y.Z
Actions 결과  : success (소요: N분)
brew-tap      : Casks/veil.rb 업데이트 확인 (sha: XXXXXXX)

brew upgrade --cask veil 으로 업데이트 가능
```

---

## 오류 처리

| 상황 | 대응 |
|------|------|
| 빌드 실패 | 중단, 오류 로그 출력 |
| push 실패 | 중단, 수동 push 명령어 안내 |
| Actions 10분 초과 | 폴링 중단, run URL 제공 |
| brew-tap 미반영 | 경고만, Actions 로그 URL 제공 |
