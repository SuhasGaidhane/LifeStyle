# Switches the Runner target's Release build to manual App Store signing and
# makes sure GoogleService-Info.plist is copied into the app.
#
# Used by .github/workflows/ios-app-store.yml after ios_signing_prepare.py.
# Reads TEAM_ID, PROFILE_NAME, SIGNING_IDENTITY and USE_ENTITLEMENTS from the
# environment. It only changes the project on the runner; nothing is committed.
require 'xcodeproj'

ios_dir = File.expand_path('../../ios', __dir__)
project = Xcodeproj::Project.open(File.join(ios_dir, 'Runner.xcodeproj'))

runner = project.targets.find { |t| t.name == 'Runner' }
abort '::error::Runner target not found in ios/Runner.xcodeproj' unless runner
release = runner.build_configurations.find { |c| c.name == 'Release' }
abort '::error::Runner target has no Release configuration' unless release

settings = release.build_settings
settings['CODE_SIGN_STYLE'] = 'Manual'
settings['DEVELOPMENT_TEAM'] = ENV.fetch('TEAM_ID')
settings['PROVISIONING_PROFILE_SPECIFIER'] = ENV.fetch('PROFILE_NAME')
settings['CODE_SIGN_IDENTITY'] = ENV.fetch('SIGNING_IDENTITY')
settings['CODE_SIGN_IDENTITY[sdk=iphoneos*]'] = ENV.fetch('SIGNING_IDENTITY')
if ENV['USE_ENTITLEMENTS'] == '1'
  settings['CODE_SIGN_ENTITLEMENTS'] = 'Runner/Runner.entitlements'
else
  settings.delete('CODE_SIGN_ENTITLEMENTS')
end

# Firebase reads GoogleService-Info.plist from the app bundle. The file is in
# ios/Runner but not listed in the Xcode project, so add it if it is missing.
plist_name = 'GoogleService-Info.plist'
if File.exist?(File.join(ios_dir, 'Runner', plist_name))
  bundled = runner.resources_build_phase.files_references.compact.any? { |ref| File.basename(ref.path.to_s) == plist_name }
  unless bundled
    group = project.main_group.groups.find { |g| g.path == 'Runner' || g.name == 'Runner' }
    ref = group&.files&.find { |f| File.basename(f.path.to_s) == plist_name }
    ref ||= group ? group.new_reference(plist_name) : project.main_group.new_reference("Runner/#{plist_name}")
    runner.add_resources([ref])
    puts "Added Runner/#{plist_name} to the app bundle (it was missing from the Xcode project)."
  end
end

project.save
puts "Runner Release signing: manual, team #{settings['DEVELOPMENT_TEAM']}, " \
     "profile '#{settings['PROVISIONING_PROFILE_SPECIFIER']}', identity '#{settings['CODE_SIGN_IDENTITY']}', " \
     "entitlements #{settings['CODE_SIGN_ENTITLEMENTS'] || 'none'}"
