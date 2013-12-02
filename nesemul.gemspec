Gem::Specification.new do |s|
  s.name        = 'nesemul'
  s.version     = '0.0.1'
  s.date        = '2013-12-02'
  s.summary     = "NesEmul"
  s.description = "Nes Emulator"
  s.authors     = ["Galaad Gauthier"]
  s.email       = 'coontail7@gmail.com'
  s.files       = Dir['**/*']
  s.executables  = ["nesemul"]
  s.require_path = 'lib'
  s.homepage    =
    'https://github.com/Galaad-Gauthier/NesEmul'
  s.license       = 'MIT'
  s.add_dependency "json"
  s.add_dependency "sdl"
end
