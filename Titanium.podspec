Pod::Spec.new do |s|

  s.name         = "Titanium"
  s.version      = "0.1"
  s.summary      = "Image viewer library"

  s.description  = <<-DESC
                   A library that provides a way to view full screen images from thumbnail previews.
                   DESC

  s.homepage     = "https://github.com/Quri/Titanium"

  s.license      = 'None'

  s.authors      = { "Camille Kander" => "camille@quri.com" }

  s.platform     = :ios, '7.0'

  s.source       = { :git => "git@github.com:quri/Titanium.git", :tag => "0.1" }

  s.source_files = 'Titanium/Titanium/*.{h,m}'

  s.requires_arc = true

end