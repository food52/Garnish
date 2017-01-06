#
# Be sure to run `pod lib lint Garnish.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'Garnish'
  s.version          = '1.0.0'
  s.summary          = 'UITextView that highlights text like Messages.app'
  s.description      = <<-DESC
Garnish is a UITextView subclass that replicates the text effects of emoji detection in Messages. GarnishTextView is extensible with custom detectors that define detection behavior and highlight colors/fonts.
DESC

  s.homepage         = 'https://github.com/Food52/Garnish'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Mike Simons' => ' mike.simons@food52.com' }
  s.source           = { :git => 'https://github.com/Food52/Garnish.git', :tag => s.version.to_s }

  s.ios.deployment_target = '9.0'

  s.source_files = 'Garnish/Classes/**/*'

  s.frameworks = 'UIKit'
end
