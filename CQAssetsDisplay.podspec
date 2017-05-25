#
# Be sure to run `pod lib lint CQAssetsDisplay.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'CQAssetsDisplay'
  s.version          = '0.1.0'
  s.summary          = '图片浏览器'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
TODO: 像tableView一样，使用非常简单的图片浏览器
                       DESC

  s.homepage         = 'https://github.com/chenchangqing/CQAssetsDisplay'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'chenchangqing198@126.com' => 'chenchangqing198@126.com' }
  s.source           = { :git => 'https://github.com/chenchangqing/CQAssetsDisplay.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.ios.deployment_target = '8.0'

  s.source_files = 'CQAssetsDisplay/Classes/**/*'
  
  # s.resource_bundles = {
  #   'CQAssetsDisplay' => ['CQAssetsDisplay/Assets/*.png']
  # }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
  s.dependency 'YYWebImage','~>1.0.5'
  s.dependency 'MCDownloadManager','~>1.0.3'
end
