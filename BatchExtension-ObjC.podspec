Pod::Spec.new do |spec|

  spec.name         = "BatchExtension-ObjC"
  spec.version      = "2.0.0"
  spec.summary      = "Batch.com iOS SDK for App Extensions. Pure Objective-C"
  spec.homepage     = "https://batch.com"
  spec.license      = { :type => "MIT", :file => "LICENSE" }
  spec.author       = { "Batch.com" => "support@batch.com" }
  
  spec.platform     = :ios, "10.0"
  spec.source       = { :git => "https://github.com/BatchLabs/Batch-iOS-SDK-Extension-ObjC.git", :tag => "#{spec.version}" }

  spec.requires_arc = true
  spec.source_files  = "Sources", "Sources/**/*.{h,m}"
  spec.public_header_files = "Classes/**/*.h"
end
