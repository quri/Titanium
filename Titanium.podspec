Pod::Spec.new do |s|

  s.name         = "Titanium"

  s.version      = "1.0"
  
  s.license      = { :type => "MIT", :file => "LICENSE" }

  s.summary      = "Image viewer library"

  s.description  = <<-DESC
                   A library that provides a way to view full screen images from thumbnail previews.
                   DESC

  s.homepage     = "https://github.com/Quri/Titanium"

  s.authors      = { "Camille Kander" => "camille@quri.com" }

  s.platform     = :ios, '7.0'

  s.source       = { :git => "https://github.com/quri/Titanium.git", :tag => "#{s.version}" }

  s.source_files = 'Titanium/Titanium/*.{h,m}'

  s.requires_arc = true

end
