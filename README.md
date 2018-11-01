![Skylark](https://github.com/rwbutler/Skylark/raw/master/Skylark.png)

[![CI Status](https://img.shields.io/travis/rwbutler/Skylark.svg?style=flat)](https://travis-ci.org/rwbutler/Skylark)
[![Version](https://img.shields.io/cocoapods/v/Skylark.svg?style=flat)](https://cocoapods.org/pods/Skylark)
[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)
[![License](https://img.shields.io/cocoapods/l/Skylark.svg?style=flat)](https://cocoapods.org/pods/Skylark)
[![Platform](https://img.shields.io/cocoapods/p/Skylark.svg?style=flat)](https://cocoapods.org/pods/Skylark)

## Features

- [x] Execute feature files containing scenarios written using Gherkin
- [x] Scenario outlines with examples
- [x] Tag expressions
- [x] Retry failed scenarios 

## Advantages
- [x] Easy set up - just add `Skylark.framework` to your UI testing target in Xcode.
- [x] No context switching between different languages - write all your test code in Swift.
- [x] The --retry flag allows tests to be retried a number of times so that a flaky test will not cause the build to be marked as a failure in your CI process (so long as it succeeds the majority of the time) however the test will be marked as flaky.
- [x] Many common steps in your scenarios will work out of the box such as checking a particular screen or element has been displayed.

## Usage

To get started import the Skylark and XCTest frameworks into your UI testing target, create an XCTestCase subclass as usual and instantiate an instance of the test runner. Ensure that your feature file has been added to your UI test bundle with the file extension `.feature` then invoke `test(featureFile:)` to run your scenarios.

    import Foundation
    import Skylark
    import XCTest
    
    class MyUITests: XCTestCase {
        // Obtain test runner instance
        lazy var testRunner = Skylark.testRunner(testCase: self)
        
        // Run scenarios from feature file
        func testFromFeatureFile() {
            testRunner.test(featureFile: "Main")
        }
       
    }

Skylark endeavors to limit the amount of additional Swift code you need to write on top of your feature files to get your tests to run. To this end, most existence checks (checking whether an element is displayed onscreen) and interaction checks e.g. tapping buttons will work out of the box. To take advantage of this functionality, simply create a JSON file with the file extension `.screen` describing the elements on a screen e.g.

    {
        "name": "Main",
        "buttons": {
            "Test": "test-button"
        }
    }

In the above the keys are the names of the elements as you would refer to them in your feature files and the values are the accessibility identifiers assigned to your UIKit elements (label text may be used where no accessibility identifier has been assigned).

For steps that require a little more work to set up the test runner provides a number of methods for registering steps to be executed. Using these you can provide the Swift code to be executed when a given step is encountered.


## Installation

### Cocoapods

[CocoaPods](http://cocoapods.org) is a dependency manager which integrates dependencies into your Xcode workspace. To install it using [RubyGems](https://rubygems.org/) run:

```
gem install cocoapods
```

To install Skylark using Cocoapods, simply add the following line to your Podfile:

```
pod "Skylark"
```

Then run the command:

```
pod install
```

For more information [see here](https://cocoapods.org/#getstarted).

### Carthage

Carthage is a dependency manager which produces a binary for manual integration into your project. It can be installed via [Homebrew](https://brew.sh/) using the commands:

```
brew update
brew install carthage
```

In order to integrate Skylark into your project via Carthage, add the following line to your project's Cartfile:

```
github "rwbutler/Skylark"
```

From the macOS Terminal run `carthage update --platform iOS` to build the framework then drag `Skylark.framework` into your Xcode project.

For more information [see here](https://github.com/Carthage/Carthage#quick-start).

## Author

Ross Butler

## License

Skylark is available under the MIT license. See the [LICENSE file](./LICENSE) for more info.

## Additional Software

### Frameworks

* [Connectivity](https://github.com/rwbutler/Connectivity) - Improves on Reachability for determining Internet connectivity in your iOS application.
* [FeatureFlags](https://github.com/rwbutler/FeatureFlags) - Allows developers to configure feature flags, run multiple A/B or MVT tests using a bundled / remotely-hosted JSON configuration file.
* [Skylark](https://github.com/rwbutler/Skylark) - Fully Swift BDD testing framework for writing Cucumber scenarios using Gherkin syntax.
* [TailorSwift](https://github.com/rwbutler/TailorSwift) - A collection of useful Swift Core Library / Foundation framework extensions.
* [TypographyKit](https://github.com/rwbutler/TypographyKit) - Consistent & accessible visual styling on iOS with Dynamic Type support.

### Tools
* [Palette](https://github.com/rwbutler/TypographyKitPalette) - Makes your [TypographyKit](https://github.com/rwbutler/TypographyKit) color palette available in Xcode Interface Builder.


[Connectivity](https://github.com/rwbutler/Connectivity)          |  [FeatureFlags](https://github.com/rwbutler/FeatureFlags)          | [Skylark](https://github.com/rwbutler/Skylark) | [TypographyKit](https://github.com/rwbutler/TypographyKit) | [Palette](https://github.com/rwbutler/TypographyKitPalette)
:-------------------------:|:-------------------------:|:-------------------------:|:-------------------------:|:-------------------------:
[![Connectivity](https://github.com/rwbutler/Connectivity/raw/master/ConnectivityLogo.png)](https://github.com/rwbutler/Connectivity)   | [![FeatureFlags](https://raw.githubusercontent.com/rwbutler/FeatureFlags/master/docs/images/feature-flags-logo.png)](https://github.com/rwbutler/FeatureFlags)   | [![Skylark](https://github.com/rwbutler/Skylark/raw/master/SkylarkLogo.png)](https://github.com/rwbutler/Skylark) |  [![TypographyKit](https://github.com/rwbutler/TypographyKit/raw/master/TypographyKitLogo.png)](https://github.com/rwbutler/TypographyKit) | [![Palette](https://github.com/rwbutler/TypographyKitPalette/raw/master/PaletteLogo.png)](https://github.com/rwbutler/TypographyKitPalette)
