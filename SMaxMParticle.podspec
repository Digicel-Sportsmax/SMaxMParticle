Pod::Spec.new do |s|
  s.name             = "SMaxMParticle"
  s.version = '0.0.1'
  s.summary          = "SMaxMParticle"
  s.description      = <<-DESC
                        SMaxMParticle container.
                       DESC
  s.homepage         = 'https://github.com/Digicel-Sportsmax/SMaxMParticle.git'
  s.license             = 'MIT'
  s.author              = { "Mohieddine Zarif" => "mohieddine.zarif@gotocme.com" }
  s.source              = { :git => 'git@github.com:Digicel-Sportsmax/SMaxMParticle.git', :tag => s.version.to_s }

  s.platform     = :ios, '10.0'
  s.requires_arc = true
  s.static_framework = true

  s.source_files = 'Classes/*.{swift,h,m}'

  s.xcconfig =  { 'CLANG_ALLOW_NON_MODULAR_INCLUDES_IN_FRAMEWORK_MODULES' => 'YES',
                  'ENABLE_BITCODE' => 'YES',
                  'SWIFT_VERSION' => '5.1'
                }
                  
  s.default_subspec = 'Core'

  s.dependency 'ZappAnalyticsPluginsSDK'
  s.dependency 'mParticle-Apple-SDK', '= 7.0.9'
end
