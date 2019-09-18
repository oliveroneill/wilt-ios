plugin 'cocoapods-keys', {
  :project => "Wilt",
  :keys => [
    "SpotifyClientID",
    "SpotifyRedirectURI",
  ]}

# Uncomment the next line to define a global platform for your project
platform :ios, '11.0'

target 'Wilt' do
  # Comment the next line if you're not using Swift and don't want to use dynamic frameworks
  use_frameworks!

  # Pods for Wilt
  pod 'Firebase/Analytics'
  pod 'Firebase/Functions'
  pod 'Firebase/Auth'
  pod 'SDWebImage', '~> 5.0'
  pod 'MaterialComponents/Cards'
  pod 'SwiftDate'
  pod 'Shimmer'
  pod 'MaterialComponents/Chips'
  pod 'SwiftIcons', '~> 2.3.2'

  target 'WiltTests' do
    inherit! :search_paths
    pod 'KIF', :configurations => ['Debug']
    pod 'Nimble-Snapshots'
  end

  target 'WiltUITests' do
    inherit! :search_paths
  end

end
