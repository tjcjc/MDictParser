#
# Be sure to run `pod lib lint MDictParser.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'MDictParser'
  s.version          = '0.1.0'
  s.summary          = 'Parse MDict with swift.'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
  Parse MDict file with swift.
                       DESC

  s.homepage         = 'https://github.com/tjcjc/MDictParser'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'tjcjc' => 'taijcjc@gmail.com' }
  s.source           = { :git => 'https://github.com/tjcjc/MDictParser.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.ios.deployment_target = '9.0'

  s.source_files = 'MDictParser/Classes/**/*'
  
  # s.resource_bundles = {
  #   'MDictParser' => ['MDictParser/Assets/*.png']
  # }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
  s.dependency 'JT_CryptoSwift', '~> 1.0.1'
  s.dependency 'JTUtils', '~> 0.1.0'
  s.dependency 'MMKV', '~> 1.0.22'
end
