source 'https://github.com/CocoaPods/Specs.git'
platform :ios, '8.0'

inhibit_all_warnings!

pod 'AFNetworking', '~> 2.1'
pod 'proj4', '~> 4.8'
pod 'geopackage-wkb-ios', :git => 'https://github.com/boundlessgeo/geopackage-wkb-ios.git', :branch => 'develop'

target :"geopackage-iosTests", :exclusive => true do
  pod 'geopackage-ios', :path => '.'
end
