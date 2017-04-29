Pod::Spec.new do |s|
  s.name         = "LocationCapture"
  s.version      = "0.0.1"
  s.summary      = "Background location capture for React Native"

  s.homepage     = "https://github.com/erikwestra/react-native-location-capture"

  s.license      = "MIT"
  s.authors      = { "Erik Westra" => "ewestra@gmail.com" }
  s.platform     = :ios, "7.0"

  s.source       = { :git => "https://github.com/erikwestra/react-native-location-capture.git" }

  s.source_files  = "ios/*.{h,m}"

  #s.dependency "React"
end

