# 宝宝营养助手 · V1

面向 1-3 岁宝宝的喂养记录与营养建议 App。**纯本地离线**：数据、照片、营养库全在手机里，不联网，不上传。

- 建档：昵称、生日（自动算年龄）、身高、体重 + 定制项（过敏 / 个头 / 缺铁风险）
- 记一餐：选餐次、多选食物 + 份量（少/中/多）、拍照留档、备注
- 看建议：当日摄入 vs 定制推荐量，逐项给"偏低/达标/偏高"提示和食物建议
- 提醒：早/中/晚三餐本地定时通知

> ⚠️ **健康免责声明**：内置营养数据为常见食材的近似值，建议由本地规则生成，**仅供参考**，不构成医疗诊断。宝宝如有特殊健康状况请咨询医生或营养师。

---

## 0. 项目结构

```
baby_nutrition/
├── pubspec.yaml                      # 依赖配置
├── lib/
│   ├── main.dart                     # 入口：初始化时区 + 通知
│   ├── app.dart                      # 根组件、主题、首页挂载
│   ├── theme.dart                    # 全局配色
│   ├── models/                       # 数据模型
│   │   ├── baby.dart                 # 宝宝档案
│   │   ├── meal.dart                 # 每餐记录（含食物编解码）
│   │   ├── food.dart                 # 食物营养模型
│   │   └── nutrient.dart             # 营养素汇总与达成率
│   ├── data/                         # 离线内置数据
│   │   ├── food_database.dart        # ~29 种常见食材营养表
│   │   └── recommendation.dart       # 1-3 岁推荐量 + 定制规则
│   ├── db/
│   │   └── database_helper.dart      # sqflite 建表与增删改查
│   ├── services/
│   │   ├── nutrition_service.dart    # 营养计算与建议引擎
│   │   └── notification_service.dart # 本地定时提醒
│   ├── widgets/
│   │   └── nutrient_progress.dart    # 营养进度条组件
│   └── pages/                        # 六个页面
│       ├── home_page.dart
│       ├── baby_profile_page.dart
│       ├── meal_record_page.dart
│       ├── meal_detail_page.dart
│       ├── nutrition_advice_page.dart
│       └── reminder_page.dart
├── android/app/src/main/AndroidManifest.xml   # 安卓权限
└── ios/Runner/Info.plist                      # iOS 权限
```

---

## ⚠️ 重要：先生成平台脚手架

本项目交付的是**核心源码（lib/）+ 依赖配置 + 双端权限文件**。完整的安卓/iOS 工程骨架（gradle、Xcode 工程等）由 Flutter 自动生成。请按下面做一次：

```bash
# 1) 在别处用 Flutter 生成一个空壳项目
flutter create baby_nutrition_scaffold --org com.yourname --project-name baby_nutrition

# 2) 把空壳里的 android/ 和 ios/ 两个文件夹，复制到本项目 baby_nutrition/ 下
#    （覆盖本项目里同名的配置，其余保持空壳生成的即可）

# 3) 用空壳生成但被本项目替换的两个权限文件核对一下：
#    - android/app/src/main/AndroidManifest.xml  ← 用本项目的（含相机/通知权限）
#    - ios/Runner/Info.plist                     ← 用本项目的（含相机/相册用途说明）

# 4) 进入本项目继续
cd baby_nutrition
flutter pub get
```

> 简言之：**lib/、pubspec.yaml、AndroidManifest.xml、Info.plist 用本项目给的；android/ 和 ios/ 里其他文件用 flutter create 生成的**。这样能保证工程可直接编译。

---

## 1. 安装开发环境（一次性）

### 通用：Flutter SDK
1. 到 Flutter 官网下载 SDK（稳定版 stable），解压到一个**不带空格、不带中文**的路径，比如 `C:\flutter`。
2. 把 `C:\flutter\bin` 加到系统环境变量 `Path`。
3. 打开终端验证：

```bash
flutter --version
flutter doctor
```

`flutter doctor` 会列出还缺什么，按提示补齐即可。

### Android 打包环境
- 安装 **Android Studio**，在 SDK Manager 里装：
  - Android SDK Platform（选 API 34 或更高）
  - Android SDK Build-Tools
  - Android SDK Command-line Tools
- 环境变量 `ANDROID_HOME` 指向 SDK 目录（如 `C:\Users\你的用户名\AppData\Local\Android\Sdk`）。
- 再跑一次 `flutter doctor`，Android 那几项全打勾即可。

### iOS 打包环境（只能用 Mac）
- 安装 **Xcode**（App Store 或苹果开发者网站）。
- 安装 CocoaPods：`sudo gem install cocoapods`
- 跑 `flutter doctor`，iOS 那几项全打勾。

> 说明：iOS 应用必须在 **macOS + Xcode** 上编译。Windows 上只能开发代码和打安卓包，iOS 包需要一台 Mac（或 Mac 云主机 / CI）。

---

## 2. 拉取依赖

进入项目目录执行：

```bash
cd baby_nutrition
flutter pub get
```

---

## 3. 先跑起来验证

连接真机（打开 USB 调试）或启动模拟器：

```bash
flutter devices          # 看有没有识别到设备
flutter run              # 安装并启动到设备
```

真机测试重点：填档案 → 记一餐（选食物+拍照）→ 看建议 → 设提醒 → 关掉网络再走一遍（验证离线可用）。

---

## 4. 打 Android APK

### 4.1 生成签名密钥（只需一次）

在项目根目录执行（Windows 用 Git Bash 或 PowerShell）：

```bash
keytool -genkey -v -keystore android/app/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

按提示设置密码和填写信息。**记住密码和 alias**，后面要用。

### 4.2 配置签名

新建文件 `android/key.properties`（⚠️ 这个文件含密码，**不要提交到 git**）：

```properties
storePassword=你的 keystore 密码
keyPassword=你的 key 密码
keyAlias=upload
storeFile=upload-keystore.jks
```

修改 `android/app/build.gradle`，在 `android {` 之前加入读取配置：

```gradle
def keystoreProperties = new Properties()
def keystorePropertiesFile = rootProject.file('key.properties')
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
}
```

在 `android { ... }` 内部加入 signingConfigs 并让 release 使用它：

```gradle
android {
    // ...原有 compileSdk 等配置...

    signingConfigs {
        release {
            keyAlias keystoreProperties['keyAlias']
            keyPassword keystoreProperties['keyPassword']
            storeFile keystoreProperties['storeFile'] ? file(keystoreProperties['storeFile']) : null
            storePassword keystoreProperties['storePassword']
        }
    }
    buildTypes {
        release {
            signingConfig signingConfigs.release
        }
    }
}
```

> 同时建议在 `android/.gitignore` 里加上 `key.properties` 和 `*.jks`。

### 4.3 出包

```bash
flutter build apk --release
```

产物在 `build/app/outputs/flutter-apk/app-release.apk`。把它发到安卓手机直接安装即可（需允许"安装未知来源应用"）。

想打体积更小的分包：

```bash
flutter build apk --split-per-abi --release
```

---

## 5. 打 iOS IPA

> 需要 Mac + Xcode + 苹果开发者账号（个人账号即可，年费）。

1. 用 Xcode 打开 `ios/Runner.xcworkspace`。
2. 在 **Signing & Capabilities** 里：
   - Team 选你的开发者账号；
   - Bundle Identifier 改成全局唯一（如 `com.你的名字.babynutrition`）。
3. 连真机，先 `flutter run` 验证能装到手机。
4. 归档出包：

```bash
flutter build ipa --release
```

产物在 `build/ios/ipa/*.ipa`。

**安装到手机的两种方式**：
- **TestFlight**（推荐）：把 IPA 上传到 App Store Connect → TestFlight → 添加测试员 → 测试员用 TestFlight App 安装。
- **本地签名安装**：Xcode 里 Archive → Distribute → Development，选真机导出并安装。

> 未加入 Apple Developer Program 时，只能装到注册的设备上做开发调试，无法长期分发。本指南只讲本地打包，不涉及上架审核。

---

## 6. 高频报错排查

| 报错 | 原因 | 解决 |
|---|---|---|
| `cmdline-tools component is missing` | 没装命令行工具 | Android Studio → SDK Manager → SDK Tools → 勾选 Android SDK Command-line Tools |
| `CocoaPods not installed` | iOS 缺 CocoaPods | `sudo gem install cocoapods`，然后 `pod install` |
| `Gradle build failed` / 卡在下载 | 依赖缓存损坏或网络 | `flutter clean` → `flutter pub get` → 重新 build |
| `Could not resolve com.android.tools.build:gradle` |  Gradle/网络源问题 | 检查网络，或配置国内 Maven 镜像源 |
| 签名 `keystore password was incorrect` | 密码/alias 填错 | 核对 `key.properties`；alias 默认 `upload` |
| iOS `Provisioning profile doesn't match` | Bundle ID 与证书不匹配 | Xcode 里改 Bundle Identifier 为已注册 App ID |
| `Waiting for another flutter command to release the startup lock` | 上次的锁没释放 | 删除 `flutter SDK 目录/bin/cache/lockfile` |
| 通知不弹 | 权限未给 / 省电限制 | 系统设置里开通知权限、关电池优化；Android 12+ 检查精确闹钟权限 |
| 拍照闪退 | 没给相机权限或未声明 | 检查 AndroidManifest / Info.plist 的权限与用途说明 |

---

## 7. 版本路线（V1 之后）

- **V2**：语音录入（端侧识别）、成长曲线、周/月营养报告、多宝宝切换、常用食物组合
- **V3**：拍照 AI 自动识别食物（需联网模型）

---

## 8. 合规提醒

- 本 App 不采集、不上传任何个人数据，无隐私政策网络要求；如要上架应用商店，仍可能需要按平台要求提交隐私说明。
- 儿童健康类建议涉及专业性，App 内已放置免责声明；对外宣传避免"诊断/治疗"等医疗化措辞。
- 本指南只提供**本地打包**方法，不承诺应用商店上架与审核结果。
