require 'xcodeproj'

project_path = '/Users/m/ipad-remote-control/TabletRemoteControl.xcodeproj'
project = Xcodeproj::Project.open(project_path)
target = project.targets.first

# Remove any existing wrong references
project.files.select { |f| f.path&.include?('xcassets') }.each do |f|
  puts "Removing: #{f.path}"
  target.resources_build_phase.files.select { |bf| bf.file_ref == f }.each(&:remove_from_project)
  f.remove_from_project
end

# Add with correct path from main group (project root)
assets_ref = project.main_group.new_reference('TabletRemoteControl/Assets.xcassets')
assets_ref.last_known_file_type = 'folder.assetcatalog'
assets_ref.source_tree = '<group>'

# Add to Resources build phase
target.resources_build_phase.add_file_reference(assets_ref)

project.save
puts "Saved"

puts "Resources phase files:"
target.resources_build_phase.files.each { |f| puts "  #{f.file_ref&.path}" }
