require 'xcodeproj'

project_path = '/Users/m/ipad-remote-control/TabletRemoteControl.xcodeproj'
project = Xcodeproj::Project.open(project_path)

def print_group(group, indent = 0)
  prefix = "  " * indent
  puts "#{prefix}[Group] name=#{group.name.inspect} path=#{group.path.inspect} display=#{group.display_name.inspect} source_tree=#{group.source_tree.inspect}"
  group.children.each do |child|
    if child.is_a?(Xcodeproj::Project::Object::PBXGroup)
      print_group(child, indent + 1)
    else
      puts "#{prefix}  [File] path=#{child.path.inspect} source_tree=#{child.source_tree.inspect}"
    end
  end
end

print_group(project.main_group)
