# Stars Initiative

A short one-line description of what your app does.

## Requirements

- A Mac running macOS 14 (Sonoma) or later
- [Xcode](https://apps.apple.com/us/app/xcode/id497799835) 15 or later (free from the Mac App Store)
- iOS 17.0+ (simulator or physical device)
- Git (comes with Xcode Command Line Tools)

> Adjust the version numbers above to match your project's deployment target.

## Download the App

You can get the source code in one of two ways.

### Option 1: Clone with Git (recommended)

Open Terminal and run:

```bash
git clone https://github.com/YOUR-USERNAME/YOUR-REPO-NAME.git
cd YOUR-REPO-NAME
```

### Option 2: Download as a ZIP

1. Go to the repository page: `https://github.com/YOUR-USERNAME/YOUR-REPO-NAME`
2. Click the green **Code** button.
3. Choose **Download ZIP**.
4. Unzip the file by double-clicking it.

## Open in Xcode

1. Open the project folder in Finder.
2. Double-click **StarsInitiative.xcodeproj** (or **StarsInitiative.xcworkspace** if the project uses CocoaPods).
3. Wait for Xcode to finish indexing and resolving any Swift Package dependencies. You can watch progress in the top status bar.

## Run the App

### On the iOS Simulator

1. At the top of Xcode, click the device selector next to the app name.
2. Choose a simulator (for example, **iPhone 15**).
3. Press **Cmd + R** or click the **Run** (play) button.

### On a Physical iPhone

1. Connect your iPhone to your Mac with a cable.
2. Select your iPhone in the device selector at the top of Xcode.
3. In the project navigator, click the project name, then select the app target and open the **Signing & Capabilities** tab.
4. Check **Automatically manage signing** and choose your **Team** (a free Apple ID works).
5. Change the **Bundle Identifier** to something unique, such as `com.yourname.StarsInitiative`.
6. Press **Cmd + R**.
7. On your iPhone, if prompted, go to **Settings > General > VPN & Device Management**, tap your developer profile, and choose **Trust**.
8. If iOS asks, enable **Developer Mode** under **Settings > Privacy & Security**.

## Troubleshooting

| Problem | Fix |
|---|---|
| "Signing for StarsInitiative requires a development team" | Select your Apple ID team under **Signing & Capabilities**. |
| Swift Package errors | Go to **File > Packages > Reset Package Caches**, then **Resolve Package Versions**. |
| Build fails after updating Xcode | Press **Cmd + Shift + K** to clean the build folder, then rebuild. |
| Simulator not listed | Open **Xcode > Settings > Platforms** and download the iOS runtime. |

## License

Please read the [LICENSE.md](LICENSE.md) file for the terms of use.
