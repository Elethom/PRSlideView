Pod::Spec.new do |s|
  s.name                  = "PRSlideView"
  s.version               = "0.2.2"
  s.summary               = "Slide view with UIKit-like methods, delegate and data source protocol."
  s.homepage              = "https://github.com/Elethom/PRSlideView"
  s.license               = { :type => "MIT", :file => "LICENSE" }
  s.author                = { "Elethom Hunter" => "elethomhunter@gmail.com" }
  s.social_media_url      = "http://twitter.com/ElethomHunter"
  s.platform              = :ios 
  s.ios.deployment_target = 5.0
  s.source                = { :git => "https://github.com/Elethom/PRSlideView.git", :tag => s.version }
  s.source_files          = "Classes/*.{h,m}"
  s.public_header_files   = "Classes/*.h"
  s.requires_arc          = true
end
