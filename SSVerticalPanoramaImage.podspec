#
# Be sure to run `pod lib lint SSVerticalPanoramaImage.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'SSVerticalPanoramaImage'
  s.version          = '1.0.0'
  s.summary          = 'Capture stunning vertical panorama images with ease and preview them instantly on the built-in screen.'

  s.description      = <<-DESC
                         'The SSVerticalPanoramaImage offers users the ability to effortlessly capture stunning vertical panorama images with a straightforward swiping motion, either from top to bottom or bottom to top. With the added convenience of inbuilt flash and zoom functionalities, it empowers users to achieve the perfect shot in a variety of lighting conditions. Furthermore, the application provides an intuitive preview feature directly on the built-in screen, ensuring users can immediately assess their captured vertical panoramas for quality and composition.'
                       DESC

  s.homepage         = 'https://github.com/SimformSolutionsPvtLtd/SSVerticalPanoramaImage'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Purvesh Dodiya' => 'purvesh.d@simformsolutions.com' }
  s.source           = { :git => 'https://github.com/SimformSolutionsPvtLtd/SSVerticalPanoramaImage.git', :tag => s.version.to_s }

  s.platform     = :ios, "14.0"
  s.ios.deployment_target = '14.0'

  s.source_files = 'SSVerticalPanoramaImage/Classes/**/*'
  s.resources = "SSVerticalPanoramaImage/Assets/**/*"
  
  s.swift_versions = ['5.0']
  s.library = 'c++'
  s.xcconfig = {
       'CLANG_CXX_LANGUAGE_STANDARD' => 'c++11',
       'CLANG_CXX_LIBRARY' => 'libc++'
  }
  s.private_header_files = [
    "SSVerticalPanoramaImage/Classes/OpenCVClass/stitching.h",
    "SSVerticalPanoramaImage/Classes/OpenCVClass/UIImage+OpenCV.h",
    "SSVerticalPanoramaImage/Classes/OpenCVClass/UIImage+Rotate.h",
  ]
  
  s.static_framework = true
  s.frameworks = 'UIKit'
  s.dependency 'OpenCV', '4.3.0'
end
