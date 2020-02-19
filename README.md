![Skylark](https://github.com/rwbutler/Skylark/raw/master/Skylark.png)

[![CI Status](https://img.shields.io/travis/rwbutler/Skylark.svg?style=flat)](https://travis-ci.org/rwbutler/Skylark)
[![Version](https://img.shields.io/cocoapods/v/Skylark.svg?style=flat)](https://cocoapods.org/pods/Skylark)
[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)
[![License](https://img.shields.io/cocoapods/l/Skylark.svg?style=flat)](https://cocoapods.org/pods/Skylark)
[![Platform](https://img.shields.io/cocoapods/p/Skylark.svg?style=flat)](https://cocoapods.org/pods/Skylark)
[![Swift 5.0](https://img.shields.io/badge/Swift-5.0-orange.svg?style=flat)](https://swift.org/)

## ⚠️ Currently Work In Progress

Skylark provides automated acceptance testing for iOS apps by translating feature files written in [Gherkin](https://cucumber.io/docs/gherkin/) into Xcode UI tests driven by the [XCTest framework](https://developer.apple.com/documentation/xctest).

To learn more about how to use Skylark, take a look at the table of contents below:

- [Features](#features)
- [Glossary](#glossary)
- [Author](#author)
- [License](#license)
- [Additional Software](#additional-software)
	- [Controls](#controls)
	- [Frameworks](#frameworks)
	- [Tools](#tools)

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

## Background

Gherkin syntax is the language used by [Cucumber](https://cucumber.io/) to define test cases to be executed. The language is designed to be easily readable to humans whilst promoting a BDD approach to testing. Test cases are defined in terms of features and scenarios with a number of scenarios comprising each feature.

## Quickstart

Skylark is a powerful UI testing framework offering many configuration options however to get up and running with minimum effort, add a `Skylark.json` configuration file to your UI testing target copying the format of the [Skylark.json provided in the example app](./Example/Skylark_UITests/Supporting%20Files/Skylark.json). This file defines:

- Context definitions: These can broadly be thought of the screens in your app i.e. which UIKit elements Skylark should expect to see on which screens.
- Application map: These are actions Skylark may take to navigate from one context to another. Defining an application map is optional however some of the more powerful features of Skylark will be unavailable to you until one is defined e.g. the ability for Skylark to automatically determine which screen it is on currently.
- Step definitions: Providing step definitions is an advanced configuration option which helps Skylark interpret the Gherkin you write. The greater the number of step definitions you provide, the more gherkin statements Skylark will be Gherkin able to interpret. If you are new to Skylark then ignore these for now.

## How It Works


## Usage

### Configuration

It is currently possible to configure Skylark in one of two ways:

- Using a single config file
- Using individual config files


#### Single config file

The framework looks for an all-in-one configuration file containing the context definitions, application map and step definitions for your application named `Skylark.json` in your test bundle. You should also define an initial context if using an all-in-one configuration file. The high-level structure of this file should follow the format below:

```
{
    "skylark": {
        "application": {
            "initial-context": "home",
            "map": {
            },
            "contexts": {
            },
            "steps": {
            }
        }
    }
}

```

If you want to get started quickly, it's worth taking a look at the example [Skylark.json](./Example/Skylark_UITests/Supporting%20Files/Skylark.json) provided with the example application. 

Using a single configuration file is only recommended for very small apps since for apps of nontrivial size it's likely you will find that your `Skylark.json` file grows to be quite large very quickly.

If you omit the `initial-context` key from this file then there are two other ways of setting the initial context - see [Initial Context](#initial-context).

#### Individual config files

This is the recommended way to configure Skylark for larger apps involving defining three separate config files:

- __Skylark-Contexts.json:__ A file containing the context definitions for your app e.g.

```
{
    "contexts": {
        "home": {
            "name": "Home",
            "elements": [{
                "name": "find product",
                "id": "home-header-view-search-button",
                "type": "buttons"
						}],
						...
				},
				...
		}
```
        
- __Skylark-Map.json:__ A file defining the application map for your app e.g.

```
{
    "map": {
        "home": [{
            "destination": "trolley",
            "actions": [
                {
                    "action": "tap",
                    "element": "tab-bar-trolley"
                }
            ]
        }, 
        ...
```

- __Skylark-Steps.json:__ A file containing the step definitions for your app e.g.

```
{
    "steps": {
        "buttons": {
            "existence": [
                "$PARAMETER is displayed",
                "$PARAMETER is shown",
                "the $PARAMETER button is displayed",
                "the $PARAMETER button is shown",
                "the $PARAMETER is displayed",
                "the $PARAMETER is shown",
                "a $PARAMETER button is displayed",
                "a $PARAMETER button is shown"
            ],
            "interaction": {
                "tap": [
                    "i tap $PARAMETER",
                    "i tap the $PARAMETER",
                    "i tap the $PARAMETER icon",
                    "i tap the $PARAMETER button",
                    "i tap the $PARAMETER link",
                    "tap the $PARAMETER button",
                    "then tap the $PARAMETER button",
                    "the $PARAMETER button is tapped",
                    "the $PARAMETER is tapped",
                    "$PARAMETER is tapped"
                ],
                ...
            }
        },
```

#### Context Definitions



#### Application Map

#### Step Definitions

#### Initial Context


There are currently three way of setting the initial context for your app:

* __Skylark.json:__ If you are using a single config file (see [Configuration](#configuration) above) then simply include the `initial-context` key as part of your application definition e.g.

```
"application": {
            "initial-context": "home",
...
```

## Concepts

* __Context:__ A context encapsulates Skylark's knowledge of  the application's state at a particular point in time. 
* __Initial Context:__ This is the state Skylark believes that your app is in when the app is first started. Therefore, if the first screen shown in your app is the home screen and you have defined a context named `home` as part of your [context definitions](#context-definitions) then this the screen Skylark will think is being shown to the user when the app is initially launched. TODO: What happens if the initial context id doesn't match any context definition?

## FAQs
### Skylark Outputs An Error
#### An initial context must be specified
If an error message is emitted indicating that an initial context must be specified this indicates that Skylark doesn't know which context to expect the app to be in when the tests start running. There are three means of specifying an initial context currently:

1. When initializing the test runner as follows:
`‌lazy var testRunner = Skylark.testRunner(testCase: self, context: "Home")`
2. By invoking `setInitialContext` e.g. `testRunner.setInitialContext("Home")`
3. As part of a `Skylark.json` configuration file by providing the context identifier as the value to the `initial-context` key e.g. 
```swift
{
    "skylark": {
        "application": {
            "initial-context": "Home",
            ...
```

### Etc
To get started import the Skylark and XCTest frameworks into your UI testing target, create an XCTestCase subclass as usual and instantiate an instance of the test runner. Ensure that your feature file has been added to your UI test bundle with the file extension `.feature` then invoke `test(featureFile:)` to run your scenarios.

```swift
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
```

Skylark endeavors to limit the amount of additional Swift code you need to write on top of your feature files to get your tests to run. To this end, most existence checks (checking whether an element is displayed onscreen) and interaction checks e.g. tapping buttons will work out of the box. To take advantage of this functionality, simply create a JSON file with the file extension `.screen` describing the elements on a screen e.g.

```json
    {
        "name": "Main",
        "buttons": {
            "Test": "test-button"
        }
    }
```

In the above the keys are the names of the elements as you would refer to them in your feature files and the values are the accessibility identifiers assigned to your UIKit elements (label text may be used where no accessibility identifier has been assigned).

For steps that require a little more work to set up the test runner provides a number of methods for registering steps to be executed. Using these you can provide the Swift code to be executed when a given step is encountered.



## Installation

### Cocoapods

[CocoaPods](http://cocoapods.org) is a dependency manager which integrates dependencies into your Xcode workspace. To install it using [RubyGems](https://rubygems.org/) run:

```bash
gem install cocoapods
```

To install Skylark using Cocoapods, simply add the following line to your Podfile:

```ruby
pod "Skylark"
```

Then run the command:

```bash
pod install
```

For more information [see here](https://cocoapods.org/#getstarted).

### Carthage

Carthage is a dependency manager which produces a binary for manual integration into your project. It can be installed via [Homebrew](https://brew.sh/) using the commands:

```bash
brew update
brew install carthage
```

In order to integrate Skylark into your project via Carthage, add the following line to your project's Cartfile:

```ogdl
github "rwbutler/Skylark"
```

From the macOS Terminal run `carthage update --platform iOS` to build the framework then drag `Skylark.framework` into your Xcode project.

For more information [see here](https://github.com/Carthage/Carthage#quick-start).

# Glossary
- Context: A context is a model representing the state of the app at a point in time. Most of the time a context represents the state of the UI for a screen in an app although it needn't necessarily represent an entire screen.
- Initial context: The initial context is the context representing the state of the app when the test launches.

## Author

[Ross Butler](https://github.com/rwbutler)

## License

Skylark is available under the MIT license. See the [LICENSE file](./LICENSE) for more info.

## Additional Software

### Controls

* [AnimatedGradientView](https://github.com/rwbutler/AnimatedGradientView) - Powerful gradient animations made simple for iOS.

|[AnimatedGradientView](https://github.com/rwbutler/AnimatedGradientView) |
|:-------------------------:|
|[![AnimatedGradientView](https://raw.githubusercontent.com/rwbutler/AnimatedGradientView/master/docs/images/animated-gradient-view-logo.png)](https://github.com/rwbutler/AnimatedGradientView) 

### Frameworks

* [Cheats](https://github.com/rwbutler/Cheats) - Retro cheat codes for modern iOS apps.
* [Connectivity](https://github.com/rwbutler/Connectivity) - Improves on Reachability for determining Internet connectivity in your iOS application.
* [FeatureFlags](https://github.com/rwbutler/FeatureFlags) - Allows developers to configure feature flags, run multiple A/B or MVT tests using a bundled / remotely-hosted JSON configuration file.
* [Hash](https://github.com/rwbutler/Hash) - Lightweight means of generating message digests and HMACs using popular hash functions including MD5, SHA-1, SHA-256.
* [Skylark](https://github.com/rwbutler/Skylark) - Fully Swift BDD testing framework for writing Cucumber scenarios using Gherkin syntax.
* [TailorSwift](https://github.com/rwbutler/TailorSwift) - A collection of useful Swift Core Library / Foundation framework extensions.
* [TypographyKit](https://github.com/rwbutler/TypographyKit) - Consistent & accessible visual styling on iOS with Dynamic Type support.
* [Updates](https://github.com/rwbutler/Updates) - Automatically detects app updates and gently prompts users to update.

|[Cheats](https://github.com/rwbutler/Cheats) |[Connectivity](https://github.com/rwbutler/Connectivity) | [FeatureFlags](https://github.com/rwbutler/FeatureFlags) | [Skylark](https://github.com/rwbutler/Skylark) | [TypographyKit](https://github.com/rwbutler/TypographyKit) | [Updates](https://github.com/rwbutler/Updates) |
|:-------------------------:|:-------------------------:|:-------------------------:|:-------------------------:|:-------------------------:|:-------------------------:|
|[![Cheats](https://raw.githubusercontent.com/rwbutler/Cheats/master/docs/images/cheats-logo.png)](https://github.com/rwbutler/Cheats) |[![Connectivity](https://github.com/rwbutler/Connectivity/raw/master/ConnectivityLogo.png)](https://github.com/rwbutler/Connectivity) | [![FeatureFlags](https://raw.githubusercontent.com/rwbutler/FeatureFlags/master/docs/images/feature-flags-logo.png)](https://github.com/rwbutler/FeatureFlags) | [![Skylark](https://github.com/rwbutler/Skylark/raw/master/SkylarkLogo.png)](https://github.com/rwbutler/Skylark) | [![TypographyKit](https://raw.githubusercontent.com/rwbutler/TypographyKit/master/docs/images/typography-kit-logo.png)](https://github.com/rwbutler/TypographyKit) | [![Updates](https://raw.githubusercontent.com/rwbutler/Updates/master/docs/images/updates-logo.png)](https://github.com/rwbutler/Updates)

### Tools

* [Clear DerivedData](https://github.com/rwbutler/ClearDerivedData) - Utility to quickly clear your DerivedData directory simply by typing `cdd` from the Terminal.
* [Config Validator](https://github.com/rwbutler/ConfigValidator) - Config Validator validates & uploads your configuration files and cache clears your CDN as part of your CI process.
* [IPA Uploader](https://github.com/rwbutler/IPAUploader) - Uploads your apps to TestFlight & App Store.
* [Palette](https://github.com/rwbutler/TypographyKitPalette) - Makes your [TypographyKit](https://github.com/rwbutler/TypographyKit) color palette available in Xcode Interface Builder.

|[Config Validator](https://github.com/rwbutler/ConfigValidator) | [IPA Uploader](https://github.com/rwbutler/IPAUploader) | [Palette](https://github.com/rwbutler/TypographyKitPalette)|
|:-------------------------:|:-------------------------:|:-------------------------:|
|[![Config Validator](https://raw.githubusercontent.com/rwbutler/ConfigValidator/master/docs/images/config-validator-logo.png)](https://github.com/rwbutler/ConfigValidator) | [![IPA Uploader](https://raw.githubusercontent.com/rwbutler/IPAUploader/master/docs/images/ipa-uploader-logo.png)](https://github.com/rwbutler/IPAUploader) | [![Palette](https://raw.githubusercontent.com/rwbutler/TypographyKitPalette/master/docs/images/typography-kit-palette-logo.png)](https://github.com/rwbutler/TypographyKitPalette)