Pod::Spec.new do |s|
  s.name          = 'FlowGraph'
  s.version       = '0.4.0'
  s.summary       = 'Simple State Machine for Swift'
  s.homepage      = 'https://github.com/objective-audio/SwiftFlowGraph'
  s.license       = { :type => 'MIT' }
  s.author        = { 'Yuki Yasoshima' => 'yukiyasos@gmail.com' }
  s.ios.deployment_target = '10.3'
  s.osx.deployment_target = '10.13'
  s.requires_arc  = true
  s.source        = { :git => 'https://github.com/objective-audio/SwiftFlowGraph.git', :tag => s.version.to_s }
  s.source_files  = 'FlowGraph/*.swift'
  s.swift_version = '4.2'
end
