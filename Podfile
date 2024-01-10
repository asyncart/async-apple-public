# Uncomment the next line to define a global platform for your project
# platform :ios, '9.0'
platform :tvos, '13.4'
inhibit_all_warnings!

target 'tvOS' do
  # Comment the next line if you don't want to use dynamic frameworks
  use_frameworks!

  # Pods for tvOS
  pod 'RealmSwift'
  pod 'Socket.IO-Client-Swift'
  pod 'SnapKit'
  pod 'ModernAVPlayer'
  pod 'Nuke'
  pod 'Sentry'
  pod 'Mixpanel-swift'

  target 'tvOSTopShelfExt' do
    inherit! :search_paths

  end

  target 'tvOSTests' do
    inherit! :search_paths
    # Pods for testing
  end

  target 'tvOSUITests' do
    # Pods for testing
  end

end
