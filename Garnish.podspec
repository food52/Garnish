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
  s.summary          = 'A short description of Garnish.'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
TODO: Add long description of the pod here.
                       DESC

  s.homepage         = 'https://github.com/Food52/Garnish'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Mike Simons' => ' mike.simons@food52.com' }
  s.source           = { :git => 'https://github.com/Food52/Garnish.git', :tag => s.version.to_s }

  s.ios.deployment_target = '9.0'

  s.source_files = 'Garnish/Classes/**/*'

  s.frameworks = 'UIKit'
end
