# Flutter APK GitHub Actions Workflow 编写指南

> 本文档用于指导 AI Agent / 开发者快速为任意 Flutter 项目编写可复用的 GitHub Actions APK 构建发布工作流。

---

## 1. 整体流程概览

```
Checkout → 环境搭建(JDK + Flutter) → 代码检查(format + analyze) → 测试 → 构建 APK → 读取版本 → 生成 Tag → 上传 Artifact → 创建 Release
```

| 步骤 | 工具/命令 | 目的 |
|------|-----------|------|
| Checkout | `actions/checkout@v4` | 拉取仓库代码 |
| 环境搭建 | `setup-java@v4` + `flutter-action@v2` | 准备 JDK 和 Flutter SDK |
| 代码检查 | `dart format` + `flutter analyze` | 保证代码格式和静态分析通过 |
| 测试 | `flutter test` | 保证单元测试通过 |
| 构建 | `flutter build apk --release` | 产出 release APK |
| 版本读取 | `grep pubspec.yaml` | 提取版本号用于 tag |
| Tag 生成 | `github.run_number` | 保证每次 tag 唯一 |
| 上传 | `upload-artifact@v4` | 保留 APK 供下载 |
| 发布 | `action-gh-release@v2` | 创建 GitHub Release 附带 APK |

---

## 2. 关键配置与最佳实践

### 2.1 触发器：`workflow_dispatch`

```yaml
on:
  workflow_dispatch:
    inputs:
      release_tag:
        description: '发布标签（留空则自动生成）'
        required: false
        default: ''
      release_notes:
        description: '发布说明（可选）'
        required: false
        default: ''
```

**注意事项：**
- `workflow_dispatch` 是手动触发，适合需要人工确认的发布场景
- `inputs` 中的参数可在运行时由用户填写，通过 `github.event.inputs.xxx` 引用
- 如果需要 CI 自动触发，可改为 `push` 到 main/master 分支时触发

### 2.2 权限：`permissions`

```yaml
permissions:
  contents: write
```

**注意事项：**
- 创建 GitHub Release 需要 `contents: write` 权限
- 必须显式声明，默认 `GITHUB_TOKEN` 权限受限
- 如果只需要构建不上传 Release，可改为 `contents: read`

### 2.3 环境搭建

#### JDK 版本

```yaml
- name: Set up JDK 25
  uses: actions/setup-java@v4
  with:
    distribution: temurin
    java-version: '25'
```

**注意事项：**
- Flutter 3.47+ 推荐 JDK 25；旧版本（3.10 以下）用 JDK 17
- `distribution` 推荐 `temurin`（Eclipse Adoptium），稳定可靠
- 如果项目有 `gradle.properties` 中指定 `org.gradle.java.home`，需与 JDK 版本保持一致

#### Flutter 版本

```yaml
- name: Set up Flutter
  uses: subosito/flutter-action@v2
  with:
    flutter-version: 3.47.1
    channel: stable
    cache: true
```

**注意事项：**
- `flutter-version` 必须与项目 `pubspec.yaml` 的 SDK 约束兼容
- `channel` 可选 `stable` / `beta` / `master`，一般用 `stable`
- `cache: true` 会缓存 Flutter SDK 和 pub 依赖，大幅加速后续构建
- **版本号要精确到 patch**（如 `3.47.1` 而非 `3.47`），避免版本漂移

### 2.4 代码检查（质量门禁）

```yaml
- name: Verify formatting
  run: dart format --output=none --set-exit-if-changed .

- name: Analyze project source
  run: flutter analyze
```

**注意事项：**
- `dart format --set-exit-if-changed`：如果代码格式不符合规范，直接让构建失败
- `flutter analyze`：静态分析，零 warning 是目标
- 这两个步骤是"质量门禁"，不要省略——否则发布的 APK 可能包含格式/分析问题
- 如果项目自定义了 `analysis_options.yaml`，`flutter analyze` 会自动遵循

### 2.5 测试

```yaml
- name: Run tests
  run: flutter test
```

**注意事项：**
- 测试失败应阻止发布，不要用 `continue-on-error: true`
- 如果需要覆盖率报告，可加 `flutter test --coverage` + `lcov` 上传
- 建议本地先跑通 `flutter test` 再提交

### 2.6 构建 APK

```yaml
- name: Build release APK
  run: flutter build apk --release
```

**注意事项：**
- `--release` 模式会做树摇（tree-shaking）和 AOT 编译，产出更小更快的 APK
- 产物默认路径：`build/app/outputs/flutter-apk/app-release.apk`
- 如果需要 ABI 拆分以减小体积，可加 `--split-per-abi`，产物会按 `arm64-v8a` / `armeabi-v7a` / `x86_64` 分目录
- 构建前会自动执行 `flutter pub get`，但建议显式加一步确保依赖完整

### 2.7 版本号读取

```yaml
- name: Read app version
  id: version
  run: |
    VERSION="$(grep -m1 '^version:' pubspec.yaml | sed 's/version: *//' | cut -d '+' -f 1)"
    echo "version=$VERSION" >> "$GITHUB_OUTPUT"
```

**注意事项：**
- `grep -m1 '^version:'` 只匹配 `pubspec.yaml` 第一行 `version:` 开头的行
- `cut -d '+' -f 1` 去掉 build number（如 `1.0.0+1` → `1.0.0`）
- 如果 `pubspec.yaml` 格式异常（如没有 `version:` 字段），此步骤会返回空值
- **输出到 `$GITHUB_OUTPUT`** 是 GitHub Actions 跨步骤传值的标准方式

### 2.8 生成唯一 Tag ⚠️ 重点

```yaml
- name: Determine release tag
  id: tag
  run: |
    if [ -n "${{ github.event.inputs.release_tag }}" ]; then
      echo "tag=${{ github.event.inputs.release_tag }}" >> "$GITHUB_OUTPUT"
    else
      echo "tag=v${{ steps.version.outputs.version }}-${{ github.run_number }}" >> "$GITHUB_OUTPUT"
    fi
```

**注意事项：**
- `github.run_number` 是仓库级自增序号，每次运行递增，天然唯一
- 格式：`v{版本号}-{run_number}`，如 `v1.0.0-42`
- 如果用户在表单中手动输入了 `release_tag`，优先使用用户指定的值
- **避坑指南**：不要用 shell 脚本（`while` 循环 + `git fetch --tags`）自己查重，GitHub Actions 的 shell 解析器对复杂 bash 语法（循环、命令替换）支持不佳，容易出现 `syntax error near unexpected token` 错误

### 2.9 上传 Artifact

```yaml
- name: Upload APK artifact
  uses: actions/upload-artifact@v4
  with:
    name: my-app-apk
    path: build/app/outputs/flutter-apk/app-release.apk
    if-no-files-found: error
    retention-days: 30
```

**注意事项：**
- `name` 是 artifact 在 Actions 页面显示的名称，建议用项目名
- `path` 支持 glob，如多 ABI 可用 `build/app/outputs/flutter-apk/*.apk`
- `if-no-files-found: error` 确保构建产物缺失时立即报错
- `retention-days` 默认 90 天，设置较短可节省存储

### 2.10 创建 GitHub Release

```yaml
- name: Create GitHub Release with APK
  uses: softprops/action-gh-release@v2
  with:
    tag_name: ${{ steps.tag.outputs.tag }}
    name: 我的应用 ${{ steps.tag.outputs.tag }}
    body: |
      ${{ github.event.inputs.release_notes }}

      ## 版本 v${{ steps.version.outputs.version }}

      - 触发方式：${{ github.event_name }}
      - 构建分支：${{ github.ref_name }}
      - 提交哈希：${{ github.sha }}

      ### 安装说明
      下载下方 app-release.apk，允许安装未知来源应用后即可安装。
    files: build/app/outputs/flutter-apk/app-release.apk
    generate_release_notes: true
    fail_on_unmatched_files: true
```

**注意事项：**
- `generate_release_notes: true` 自动生成 Release Notes（基于 PR 合并历史）
- `fail_on_unmatched_files: true` 如果 APK 路径不对，立即报错
- `tag_name` 对应上面生成的 tag，Release 会自动关联
- 如果 tag 已存在，Release 会更新到该 tag（不会覆盖已有 tag）

---

## 3. 完整模板

以下是可直接复制并微调的完整模板：

```yaml
name: Build & Release APK

on:
  workflow_dispatch:
    inputs:
      release_tag:
        description: '发布标签（留空自动生成 v版本号-runNumber）'
        required: false
        default: ''
      release_notes:
        description: '发布说明（可选）'
        required: false
        default: ''

permissions:
  contents: write

jobs:
  build:
    name: Build APK (Release)
    runs-on: ubuntu-latest
    timeout-minutes: 45

    steps:
      # 1. 拉取代码
      - name: Checkout repository
        uses: actions/checkout@v4

      # 2. JDK 环境（Flutter 3.47+ 用 JDK 25，旧版本用 JDK 17）
      - name: Set up JDK 25
        uses: actions/setup-java@v4
        with:
          distribution: temurin
          java-version: '25'

      # 3. Flutter 环境
      - name: Set up Flutter
        uses: subosito/flutter-action@v2
        with:
          flutter-version: 3.47.1
          channel: stable
          cache: true

      # 4. 验证环境
      - name: Show Flutter version
        run: flutter --version

      # 5. 安装依赖
      - name: Install pub dependencies
        run: flutter pub get

      # 6. 代码格式检查
      - name: Verify formatting
        run: dart format --output=none --set-exit-if-changed .

      # 7. 静态分析
      - name: Analyze project source
        run: flutter analyze

      # 8. 运行测试
      - name: Run tests
        run: flutter test

      # 9. 构建 Release APK
      - name: Build release APK
        run: flutter build apk --release

      # 10. 读取版本号
      - name: Read app version
        id: version
        run: |
          VERSION="$(grep -m1 '^version:' pubspec.yaml | sed 's/version: *//' | cut -d '+' -f 1)"
          echo "version=$VERSION" >> "$GITHUB_OUTPUT"

      # 11. 生成唯一 Tag
      - name: Determine release tag
        id: tag
        run: |
          if [ -n "${{ github.event.inputs.release_tag }}" ]; then
            echo "tag=${{ github.event.inputs.release_tag }}" >> "$GITHUB_OUTPUT"
          else
            echo "tag=v${{ steps.version.outputs.version }}-${{ github.run_number }}" >> "$GITHUB_OUTPUT"
          fi

      # 12. 上传 APK 为 Artifact
      - name: Upload APK artifact
        uses: actions/upload-artifact@v4
        with:
          name: my-app-apk
          path: build/app/outputs/flutter-apk/app-release.apk
          if-no-files-found: error
          retention-days: 30

      # 13. 创建 GitHub Release
      - name: Create GitHub Release with APK
        uses: softprops/action-gh-release@v2
        with:
          tag_name: ${{ steps.tag.outputs.tag }}
          name: 我的应用 ${{ steps.tag.outputs.tag }}
          body: |
            ${{ github.event.inputs.release_notes }}

            ## 版本 v${{ steps.version.outputs.version }}

            - 触发方式：${{ github.event_name }}
            - 构建分支：${{ github.ref_name }}
            - 提交哈希：${{ github.sha }}
          files: build/app/outputs/flutter-apk/app-release.apk
          generate_release_notes: true
          fail_on_unmatched_files: true
```

---

## 4. 需要根据项目修改的占位项汇总

| 占位项 | 示例值 | 说明 |
|--------|--------|------|
| `flutter-version` | `3.47.1` | 目标项目的 Flutter 版本 |
| `java-version` | `'25'` | Flutter 3.47+ 用 25，旧版本用 17 |
| `channel` | `stable` | `stable` / `beta` / `master` |
| `my-app-apk` | 项目名 + `-apk` | artifact 名称 |
| `我的应用` | 项目名 | Release 标题和正文中的项目名 |
| APK 路径 | `build/app/outputs/flutter-apk/app-release.apk` | 标准路径，一般无需修改 |

---

## 5. 常见坑与解决方案

### ❌ 坑 1：shell 语法错误

```
line 11: syntax error near unexpected token `then'
```

**原因**：GitHub Actions 的 shell 解析器对复杂 bash 语法（嵌套循环、命令替换、heredoc）支持不佳。

**解决**：保持 `run` 脚本简洁，用 `github.run_number` 替代 shell 查重逻辑，避免 `while` / `for` 循环和复杂条件嵌套。

### ❌ 坑 2：Tag 已存在导致 Release 创建失败

```
Validation Failed: {"resource":"Release","code":"already_exists"}
```

**原因**：用固定 tag（如 `v1.0.0`）重复创建 Release。

**解决**：使用 `github.run_number` 拼接唯一 tag，或在 shell 中查重后追加后缀（但注意坑 1）。

### ❌ 坑 3：Release 创建失败，权限不足

```
Resource not accessible by integration
```

**原因**：缺少 `contents: write` 权限。

**解决**：在 workflow 顶部添加：
```yaml
permissions:
  contents: write
```

### ❌ 坑 4：APK 文件找不到

```
No files were found with the provided path
```

**原因**：项目没有 Android 目录，或 APK 产物路径不对。

**解决**：
1. 确认项目包含 `android/` 目录
2. 确认 `flutter build apk --release` 本地能成功
3. 如果用了 `--split-per-abi`，路径改为 `build/app/outputs/flutter-apk/*.apk`

### ❌ 坑 5：Flutter 版本不兼容

```
Error: Couldn't resolve the package ...
```

**原因**：指定的 Flutter 版本与 `pubspec.yaml` 的 SDK 约束不兼容。

**解决**：检查 `pubspec.yaml` 中 `environment.sdk` 的约束，确保 Flutter SDK 版本满足。

### ❌ 坑 6：缓存导致旧依赖

```
Dart SDK snapshot requires recompilation
```

**原因**：`cache: true` 缓存了旧的 pub 依赖。

**解决**：在 Actions 页面重新运行时勾选 "Run this workflow" 下的 "Clear cache"，或手动清除缓存。

### ❌ 坑 7：Release Notes 中的换行不生效

**原因**：YAML 的 `|` 块标量中，空行会被保留但 GitHub Release Markdown 解析可能不符合预期。

**解决**：在 Release body 中使用标准 Markdown 格式，段落之间留一个空行，不要用 `\n` 替代真实换行。

---

## 6. 进阶可选配置

### 6.1 多平台支持（Web + APK）

```yaml
strategy:
  matrix:
    platform: [android, web]
```

### 6.2 自动触发（push 到 main 时）

```yaml
on:
  push:
    branches: [main]
```

### 6.3 签名构建（Release 签名）

```yaml
- name: Import signing key
  run: |
    echo "${{ secrets.KEY_BASE64 }}" | base64 --decode > android/app/upload-keystore.jks
  env:
    KEY_BASE64: ${{ secrets.KEY_BASE64 }}
```

### 6.4 覆盖率上传

```yaml
- name: Run tests with coverage
  run: flutter test --coverage

- name: Upload coverage
  uses: codecov/codecov-action@v4
  with:
    files: coverage/lcov.info
```

### 6.5 构建时长优化

```yaml
# 用官方的 Dart/Flutter 缓存
- name: Cache Flutter packages
  uses: actions/cache@v4
  with:
    path: ~/.pub-cache
    key: pub-${{ runner.os }}-${{ hashFiles('pubspec.lock') }}
```

---

## 7. 检查清单

编写完成后，按此清单逐项验证：

- [ ] `permissions` 包含 `contents: write`
- [ ] JDK 版本与 Flutter 版本匹配（3.47+ → JDK 25）
- [ ] Flutter 版本精确到 patch 号
- [ ] `dart format --set-exit-if-changed` 作为质量门禁
- [ ] `flutter analyze` 零 issues
- [ ] `flutter test` 全部通过
- [ ] APK 产物路径正确
- [ ] Tag 生成使用 `github.run_number` 保证唯一
- [ ] `fail_on_unmatched_files: true` 防止 Release 关联空文件
- [ ] Release body 中引用的变量均已通过 `$GITHUB_OUTPUT` 传递
- [ ] `pubspec.yaml` 中的 `version:` 字段存在且格式规范
