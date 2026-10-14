# 奶娃片刻

一个安静的离线番茄钟，支持 Windows、Android、macOS 和 iPhone。默认 25 分钟专注、5 分钟短休息、15 分钟长休息；完成四轮专注后长休息。支持暂停、恢复、本地统计、环境声、全屏和自定义背景。

## 下载与安装

**所有正式版本都在 [统一下载页](https://github.com/Charles0108/naiwa-moment-app/releases/latest)。** 普通使用者下载下面的安装包，无需安装 Flutter 或下载源码。

| 平台 | 下载 | 安装方法 |
| --- | --- | --- |
| Windows 10/11，64 位 | [Windows 安装器](https://github.com/Charles0108/naiwa-moment-app/releases/latest/download/NaiwaMoment-Windows-Setup.exe) | 双击安装器，选择安装位置 |
| Android 7.0 及以上 | [Android APK](https://github.com/Charles0108/naiwa-moment-app/releases/latest/download/NaiwaMoment-Android.apk) | 手机上打开 APK，按系统提示允许此次安装 |
| macOS 12 及以上，Intel / Apple 芯片 | [macOS 应用](https://github.com/Charles0108/naiwa-moment-app/releases/latest/download/NaiwaMoment-macOS.zip) | 解压，将应用拖入「应用程序」；首次打开按系统提示确认来源 |
| iPhone / iPad，iOS 15 及以上 | [待自签 IPA](https://github.com/Charles0108/naiwa-moment-app/releases/latest/download/NaiwaMoment-iOS-unsigned.ipa) | 使用 Sideloadly 和自己的 Apple ID 签名安装 |

未上架应用商店。Windows/macOS 安装包没有商业发行签名，首次安装或打开时可能需要系统确认。

### iPhone 安装

在 Windows 上按 [Sideloadly 官方说明](https://sideloadly.io/) 安装其工具及 Apple 网页版 iTunes/iCloud 支持组件。用 USB 连接并信任手机，将 IPA 拖入 Sideloadly，输入自己的 Apple ID，按提示完成安装和手机上的信任/开发者模式确认。免费 Apple ID 签名有效期为 7 天，可使用自动刷新；电脑与手机需要能连接。请在工具中输入账号信息，不要上传到仓库或发到问题反馈中。

## 功能与画面

- 专注、短休息、长休息；时间可自行设置，结束后由你开始下一周期。
- 本地保存计时状态与统计，重开应用后恢复当前周期；暂停和休息不计为专注。
- 33 个场景：9 个 1080×1920、60 fps 的静音循环视频，14 张视频静帧，10 张艺术背景。
- 细雨、林间风、海浪与轻柔结束提示音；图片、视频和声音均随应用打包，可离线使用。
- 电脑完整显示画面，两侧由同一画面的放大模糊副本填充；手机铺满显示。
- 支持导入自己的图片或视频。应用图标采用奶龙参考图片。

应用没有账号系统、分析统计服务或用户数据上传功能。专注记录、设置和导入素材保存在设备本地。

## Android 验证状态

当前发布包已完成代码检查、计时/布局测试、发布构建和 APK 签名验证。Android 模拟器运行验证结果将在本次发布说明中记录；没有 Android 真机测试结果时，不将其标为实机验证通过。

首次在真实手机安装后，可以这样检查：启动并切换图片/视频；开启环境声；将专注时长改为 1 分钟，检查暂停/继续与结束；计时中切到后台再返回，检查剩余时间；关闭重开应用，检查记录和统计。不同品牌手机的后台行为以实测为准。

## 素材致谢

奶娃视频及 14 张静帧来自 B站 UP主 **防御老猫** 的视频 **「【奶娃】“悲观人生”」**。感谢创作者提供这些温柔的画面。素材库选择页面也显示此致谢。

角色及视频素材的权利归各自权利人所有；代码公开不改变这些素材的权利归属。

## 从源码构建

工程位于 `app/`，使用 Flutter **3.47.7** / Dart **3.13.5**，依赖版本由 `pubspec.lock` 锁定。

```sh
cd app
flutter pub get
flutter analyze
flutter test
flutter build windows --release
flutter build apk --release
```

Windows 构建需 Visual Studio C++ 桌面工具；Android 构建需 JDK 和 Android SDK。Android 自行构建默认使用开发签名，正式发布可通过 `NAIWA_ANDROID_KEYSTORE`、`NAIWA_ANDROID_STORE_PASSWORD`、`NAIWA_ANDROID_KEY_PASSWORD` 指定自己的签名资料。签名文件与口令均不在仓库中。

macOS/iOS 在 Mac 上执行 `bash tools/build_apple.sh`；也可以手动运行仓库中的「Build Apple apps」工作流。iOS 生成未签名 IPA，安装前仍需使用自己的 Apple ID 签名。

`tools/update_icons.py` 转换原生图标尺寸。`tools/import_scene_pack.py` 导入带 `manifest.json` 的素材包，倒放循环已经烘焙在文件内，播放器只需普通循环。

## 反馈

请通过本仓库 Issues 提供操作步骤、系统版本和错误截图；不要附 Apple ID 密码、签名密钥或设备上的私人文件。
