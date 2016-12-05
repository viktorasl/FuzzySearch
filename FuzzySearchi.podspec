Pod::Spec.new do |s|
  s.name = 'FuzzySearchi'
  s.version = '1.1.0'
  s.license = 'MIT'
  s.summary = 'Lightweight Fuzzy evaluation protocol with CollectionType extension'
  s.homepage = 'https://github.com/viktorasl/FuzzySearch'
  s.authors = { 'Viktoras Laukevičius' => 'viktoras.laukevicius@yahoo.com' }
  s.source = { :git => 'https://github.com/viktorasl/FuzzySearch.git', :tag => s.version }

  s.ios.deployment_target = '8.0'
  s.osx.deployment_target = '10.10'
  s.tvos.deployment_target = '9.0'

  s.source_files = 'Source/*.swift'
end