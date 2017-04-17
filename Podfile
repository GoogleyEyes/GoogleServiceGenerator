platform :osx, '10.12'
use_frameworks!

target 'GoogleServiceGenerator' do
    pod 'GoogleAPISwiftClient/Discovery', :path => '~/Documents/Developer/iOS/Objective-C_Resources/GoogleClient'
    
    pod 'PathKit', '~> 0.7.0'
    pod 'Stencil', '~> 0.6.0'
end

post_install do |installer|
    installer.pods_project.targets.each do |target|
        target.build_configurations.each do |configuration|
            configuration.build_settings['SWIFT_VERSION'] = "3.0"
        end
    end
end
