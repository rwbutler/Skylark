Pod::Spec.new do |s|
  s.name             = 'Skylark'
  s.version          = '0.2.0'
  s.summary          = 'Pure Swift BDD testing framework for writing Cucumber scenarios using Gherkin syntax'
  s.swift_version    = '5.0'
  s.description      = <<-DESC
  Implementation of Cucumber written in pure Swift using XCTest. Allows the execution of feature files containing scenarios written in Gherkin syntax.
                       DESC
  s.homepage         = 'https://github.com/rwbutler/Skylark'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Ross Butler' => 'github@rwbutler.com' }
  s.source           = { :git => 'https://github.com/rwbutler/Skylark.git', :tag => s.version.to_s }
  s.ios.deployment_target = '9.3'
  s.framework = 'XCTest'
  s.source_files = 'Skylark/**/*.swift'
end
