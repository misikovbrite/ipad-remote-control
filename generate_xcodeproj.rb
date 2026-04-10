#!/usr/bin/env ruby
require 'xcodeproj'

APP_NAME = "TabletRemoteControl"
BUNDLE_ID = "ipad remote control - ipadremotecontrolapp"
TEAM_ID = "5487HDH2B9"
DEPLOYMENT_TARGET = "17.0"

project_path = "#{APP_NAME}/#{APP_NAME}.xcodeproj"
project = Xcodeproj::Project.new(project_path)

# Main app target
target = project.new_target(:application, APP_NAME, :ios, DEPLOYMENT_TARGET)
target.product_name = APP_NAME

# Build settings
[project.build_configuration_list, target.build_configuration_list].each do |list|
  list.build_configurations.each do |config|
    config.build_settings.merge!({
      "PRODUCT_BUNDLE_IDENTIFIER" => BUNDLE_ID,
      "DEVELOPMENT_TEAM" => TEAM_ID,
      "IPHONEOS_DEPLOYMENT_TARGET" => DEPLOYMENT_TARGET,
      "SWIFT_VERSION" => "5.9",
      "TARGETED_DEVICE_FAMILY" => "2",
      "INFOPLIST_FILE" => "#{APP_NAME}/Sources/App/Info.plist",
      "CODE_SIGN_STYLE" => "Automatic",
      "ENABLE_PREVIEWS" => "YES",
      "SWIFT_EMIT_LOC_STRINGS" => "YES",
    })
  end
end

# Main group
main_group = project.main_group
sources_group = main_group.new_group(APP_NAME, APP_NAME)

# Add all Swift source files recursively
def add_files_to_group(group, dir, target, project)
  Dir.entries(dir).sort.each do |entry|
    next if entry.start_with?(".")
    path = File.join(dir, entry)
    if File.directory?(path)
      subgroup = group.new_group(entry, entry)
      add_files_to_group(subgroup, path, target, project)
    elsif entry.end_with?(".swift")
      file_ref = group.new_file(entry)
      target.add_file_references([file_ref])
    elsif entry == "Info.plist"
      group.new_file(entry)
    elsif entry.end_with?(".xcassets")
      ref = group.new_file(entry)
      target.add_resources([ref])
    end
  end
end

add_files_to_group(sources_group, "#{APP_NAME}/Sources", target, project)

# Add Assets.xcassets if exists
assets_path = "#{APP_NAME}/Assets.xcassets"
if File.exist?(assets_path)
  assets_ref = sources_group.new_file("Assets.xcassets")
  target.add_resources([assets_ref])
end

project.save
puts "✅ #{project_path} created successfully!"
