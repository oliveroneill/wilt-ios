plugin 'cocoapods-keys', {
  :project => "Wilt",
  :target => ["Wilt", "WiltUITests"],
  :keys => [
    "SpotifyClientID",
    "SpotifyRedirectURI",
    "SpotifyAuthTokenURL",
  ]}

inhibit_all_warnings!

def wilt_dependencies
  pod 'Firebase/Analytics'
  pod 'Firebase/Functions'
  pod 'Firebase/Auth'
  pod 'SDWebImage'
  pod 'MaterialComponents/Cards'
  pod 'SwiftDate'
  pod 'Shimmer'
  pod 'MaterialComponents/Chips'
  pod 'SwiftIcons'
end

# Uncomment the next line to define a global platform for your project
platform :ios, '11.0'

target 'Wilt' do
  # Comment the next line if you're not using Swift and don't want to use dynamic frameworks
  use_frameworks!

  # Pods for Wilt
  wilt_dependencies

  target 'WiltTests' do
    inherit! :search_paths
    pod 'KIF', :configurations => ['Debug']
    pod 'Nimble-Snapshots'
  end

end

target 'WiltUITests' do
  use_frameworks!
  wilt_dependencies
end
