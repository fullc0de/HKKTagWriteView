#
# Be sure to run `pod lib lint TagWriteView.podspec' to ensure this is a
# valid spec and remove all comments before submitting the spec.
#
# Any lines starting with a # are optional, but encouraged
#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = "TagWriteView"
  s.version          = "1.4.0"
  s.summary          = "The smart input custom view for Evernote app style tagging."
  s.homepage         = "https://github.com/fullc0de/HKKTagWriteView"
  # s.screenshots     = "www.example.com/screenshots_1", "www.example.com/screenshots_2"
  s.license          = 'MIT'
  s.author           = { "kyokook" => "fullc0de@gmail.com" }
  s.source           = { :git => "https://github.com/fullc0de/HKKTagWriteView.git", :tag => s.version.to_s }

  s.platform     = :ios, '8.0'
  s.requires_arc = true

  s.source_files = 'TagWriteViewTest/*.swift'
end
