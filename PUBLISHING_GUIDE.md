# 发布 Guji-Diff 到 pub.dev 指南

## 📦 发布前准备

### 1. 完善 pubspec.yaml

确保 `dart/pubspec.yaml` 包含必要信息：

```yaml
name: guji_diff
version: 0.1.0  # 遵循语义化版本
description: >
  A robust collation engine for ancient and modern Chinese texts,
  supporting verbatim and structural comparison, variant character
  normalization, and statistical analysis. Platform-adaptive with
  native OpenCC FFI and Web OpenCC-JS support.

homepage: https://github.com/sheldonlidev/guji-diff
repository: https://github.com/sheldonlidev/guji-diff
issue_tracker: https://github.com/sheldonlidev/guji-diff/issues
documentation: https://github.com/sheldonlidev/guji-diff#readme

# 可选：添加主题标签
topics:
  - chinese
  - text-comparison
  - collation
  - ancient-texts
  - opencc

environment:
  sdk: ^3.10.3
  flutter: ">=1.17.0"

dependencies:
  flutter:
    sdk: flutter
  diff_match_patch: ^0.4.1
  opencc: ^1.1.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^6.0.0
```

### 2. 添加 LICENSE 文件

在项目根目录创建 `LICENSE` 文件（如果还没有）：

```bash
cd c:\Users\lisdp\workspace\guji-diff
```

创建 `LICENSE` 文件，例如使用 MIT License：

```
MIT License

Copyright (c) 2024 [Your Name]

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

### 3. 创建 CHANGELOG.md

在 `dart/` 目录创建 `CHANGELOG.md`：

```markdown
## 0.1.0

* Initial release
* Verbatim collation with diff-match-patch
* Structural collation with JSON Patch output
* Statistical analysis and pattern recognition
* Platform-adaptive OpenCC integration:
  - Native platforms: OpenCC FFI
  - Web platform: OpenCC-JS
* Support for traditional/simplified Chinese conversion
* Variant character mapping
* Punctuation handling options
```

### 4. 确保有 README.md

`dart/` 目录需要有 README.md（可以从根目录复制或创建简化版本）。

---

## 🚀 发布步骤

### 步骤 1: 检查包结构

```bash
cd dart

# 验证包结构
flutter pub publish --dry-run
```

这会检查：
- ✅ pubspec.yaml 格式正确
- ✅ 必需文件存在（README.md, LICENSE, CHANGELOG.md）
- ✅ 没有敏感文件（私钥、密码等）
- ✅ 依赖版本合法

### 步骤 2: 分析代码质量

```bash
# 运行代码分析
flutter analyze

# 运行测试
flutter test

# 检查格式
dart format --set-exit-if-changed .
```

确保：
- ✅ 没有分析错误
- ✅ 所有测试通过
- ✅ 代码格式正确

### 步骤 3: 登录 pub.dev

如果第一次发布，需要登录：

```bash
# 使用 Google 账号登录
dart pub login
```

这会打开浏览器让你授权。

### 步骤 4: 发布包

```bash
cd dart

# 正式发布
flutter pub publish
```

系统会：
1. 再次运行 `--dry-run` 检查
2. 显示将要上传的文件列表
3. 要求确认（输入 `y`）
4. 上传到 pub.dev

### 步骤 5: 验证发布

访问：https://pub.dev/packages/guji_diff

确认：
- ✅ 版本号正确
- ✅ README 显示正常
- ✅ API 文档生成成功
- ✅ 示例代码清晰

---

## 📝 发布清单

在发布前确认以下内容：

### 必需文件
- [ ] `dart/pubspec.yaml` - 包含完整元数据
- [ ] `dart/README.md` - 使用说明（已完成）
- [ ] `LICENSE` - 开源许可证
- [ ] `dart/CHANGELOG.md` - 版本历史

### pubspec.yaml 必需字段
- [ ] `name` - 包名称
- [ ] `version` - 版本号（语义化版本）
- [ ] `description` - 清晰的描述（60-180 字符）
- [ ] `homepage` 或 `repository` - 项目主页
- [ ] `environment.sdk` - Dart SDK 版本约束

### 代码质量
- [ ] `flutter analyze` 无错误
- [ ] `flutter test` 全部通过
- [ ] `dart format .` 格式正确
- [ ] 没有未使用的依赖

### 文档
- [ ] README 包含安装说明
- [ ] README 包含使用示例
- [ ] README 包含 Web 部署说明
- [ ] API 文档注释完整

---

## 🔄 更新已发布的包

### 更新版本号

遵循**语义化版本**规则：

```
MAJOR.MINOR.PATCH

例如：1.2.3
  ↑   ↑   ↑
  |   |   └─ 补丁版本（bug 修复）
  |   └───── 次版本（新功能，向后兼容）
  └─────── 主版本（破坏性变更）
```

### 发布新版本步骤

1. **修改代码**

2. **更新版本号**（`pubspec.yaml`）
   ```yaml
   version: 0.1.1  # 或 0.2.0, 1.0.0
   ```

3. **更新 CHANGELOG.md**
   ```markdown
   ## 0.1.1

   * Fixed OpenCC initialization bug
   * Updated documentation
   * Added more variant character mappings
   ```

4. **运行测试**
   ```bash
   flutter test
   flutter analyze
   ```

5. **发布**
   ```bash
   cd dart
   flutter pub publish
   ```

---

## 🌐 在其他项目中使用

### 安装方式 1: pub.dev（推荐）

发布成功后，其他项目可以直接引用：

```yaml
# 其他项目的 pubspec.yaml
dependencies:
  guji_diff: ^0.1.0  # 自动获取最新兼容版本
```

### 安装方式 2: Git 仓库

也可以直接从 Git 引用：

```yaml
dependencies:
  guji_diff:
    git:
      url: https://github.com/sheldonlidev/guji-diff.git
      path: dart
      ref: main  # 或特定 tag/commit
```

### 安装方式 3: 本地路径（开发用）

```yaml
dependencies:
  guji_diff:
    path: ../guji-diff/dart
```

---

## 📊 pub.dev 包评分

pub.dev 会根据以下标准评分（最高 140 分）：

### 文档 (30 分)
- [ ] 有 README.md (10 分)
- [ ] 有示例 (10 分)
- [ ] API 文档完整 (10 分)

### 平台支持 (20 分)
- [ ] 支持多平台（我们支持所有平台）

### Pub Points (50 分)
- [ ] 遵循 Dart 文件惯例
- [ ] 提供 CHANGELOG
- [ ] 有 LICENSE
- [ ] 版本约束合理
- [ ] 代码格式正确

### 流行度 (40 分)
- 随时间累积（下载量、点赞等）

---

## ⚠️ 常见错误和解决方案

### 错误 1: 包名已存在

```
Package name 'guji_diff' is already taken
```

**解决方案**：更改包名，例如：
- `guji_diff_pro`
- `chinese_text_collation`
- `ancient_text_diff`

### 错误 2: 版本号冲突

```
Version 0.1.0 has already been published
```

**解决方案**：增加版本号到 `0.1.1` 或更高。

### 错误 3: 描述太短或太长

```
Description must be between 60 and 180 characters
```

**解决方案**：调整 `pubspec.yaml` 的 `description` 字段。

### 错误 4: 缺少 LICENSE

```
Missing LICENSE file
```

**解决方案**：在项目根目录或 `dart/` 目录添加 LICENSE 文件。

### 错误 5: 依赖版本过于严格

```
Dependency constraints are too tight
```

**解决方案**：使用范围版本约束：
```yaml
dependencies:
  diff_match_patch: ^0.4.1  # 好：接受 0.4.x
  opencc: ^1.1.0            # 好：接受 1.x.x

  # 避免：
  # diff_match_patch: 0.4.1  # 太严格
```

---

## 🎯 发布后的最佳实践

### 1. 监控问题和反馈

- 定期检查 GitHub Issues
- 回复 pub.dev 上的评论
- 关注使用统计

### 2. 保持更新

- 修复 bug 及时发布补丁版本
- 添加新功能发布次版本
- 破坏性变更提前通知（主版本）

### 3. 改进文档

- 根据用户反馈完善 README
- 添加更多示例
- 更新常见问题

### 4. 版本管理

- 使用 Git tags 标记版本
  ```bash
  git tag v0.1.0
  git push origin v0.1.0
  ```

- 在 GitHub 创建 Release

### 5. 社区互动

- 鼓励贡献（CONTRIBUTING.md）
- 欢迎 Pull Requests
- 标记好的第一个 Issue（good first issue）

---

## 📚 有用的资源

- [pub.dev Publishing Guide](https://dart.dev/tools/pub/publishing)
- [Package Layout Conventions](https://dart.dev/tools/pub/package-layout)
- [Versioning](https://dart.dev/tools/pub/versioning)
- [Writing Package Pages](https://dart.dev/tools/pub/writing-package-pages)

---

## 🔍 验证清单

发布前最后检查：

```bash
cd dart

# 1. 清理和获取依赖
flutter clean
flutter pub get

# 2. 运行所有测试
flutter test

# 3. 代码分析
flutter analyze

# 4. 格式检查
dart format --set-exit-if-changed .

# 5. 模拟发布
flutter pub publish --dry-run

# 6. 确认一切正常后发布
flutter pub publish
```

---

**准备好后，运行 `flutter pub publish` 即可发布！** 🚀
