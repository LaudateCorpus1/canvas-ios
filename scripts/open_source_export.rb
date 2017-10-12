require 'xcodeproj'
require 'fileutils'
require 'plist'
require 'optparse'

options = {}
OptionParser.new do |opts|
  opts.banner = 'Usage: open_source_export.rb [options]'

  opts.on('-s', '--skip-copy', 'Skips copying over all of the files.') do |v|
    options[:skip_copy] = v
  end

  opts.on('-g', '--skip-git-clean', 'Skips doing a git clean before export.') do |v|
    options[:skip_clean] = v
  end
end.parse!

workspace_name = 'AllTheThings.xcworkspace'

# Quick check to make sure this script is run in the right place
raise "This script must be run from the same directory that contains #{workspace_name}" unless File.exist?(workspace_name)

unless options[:skip_clean]
  puts "Warning: this will remove any uncommitted code. Press any key to continue."
  gets

  # Export from develop. Remove files not tracked in git.
  ['git checkout develop', 'git clean -dfx', 'git reset --hard'].each do |command|
    raise "command failed: #{command}" unless system(command)
  end
end

targets = [workspace_name,
           'CanvasCore',
           'Canvas',
           'Parent',
           'rn',
           'Frameworks',
           'Podfile',
           'Podfile.lock',
           'ExternalFrameworks',
           'secrets.plist',
           '.gitignore',
           'fastlane',
           'setup.sh']

destination          = 'ios-open-source'
frameworks_path      = File.join(destination, 'Frameworks')
canvas_core_path     = File.join(destination, 'CanvasCore')
workspace_path       = File.join(destination, workspace_name)
podfile_path         = File.join(destination, 'Podfile')

# The groups in the workspace that shouldn't be included
groups_to_remove = %w[]

# Frameworks that should be removed as well
# DoNotShipThis - has auth tokens for test accounts
# SoAutomated - has DVR network recordings with private data
# EverythingBagel - I don't know why this is not open source
frameworks_to_remove = %w[DoNotShipThis SoAutomated EverythingBagel]

puts "Copying all required files and folders"
unless options[:skip_copy]
  FileUtils.rm_r destination if File.exists? destination
  FileUtils.mkdir destination

  targets.each do |file|
    FileUtils.cp_r file, File.join(destination, file) if File.directory? file
    FileUtils.cp file, File.join(destination, file) unless File.directory? file
  end
end

workspace     = Xcodeproj::Workspace.new_from_xcworkspace(workspace_path)
workspace_xml = workspace.document

# Goes through all the groups and all of the files and removes anything that shouldn't be there
puts "Pruning Xcode workspace"
workspace_xml.elements.each do |root|
  root.elements.each do |element|
    name = element.attribute('name').to_s
    root.delete element if groups_to_remove.any? { |file| file == name }
    element.elements.each do |child|
      location = child.attribute('location').to_s
      element.delete child if frameworks_to_remove.any? { |file| location.include?(file) }
    end
  end
end

# Package up the new workspace
fixed_workspace = Xcodeproj::Workspace.from_s(workspace_xml.to_s, workspace_path)
raise 'error creating fixed up workspace' unless fixed_workspace
fixed_workspace.save_as(workspace_path)

puts "Removing Fabric build scripts"
def remove_fabric_from_project(project_path)
  project = Xcodeproj::Project.open(project_path)
  project.targets.each do |target|
    fabric_phase = target.shell_script_build_phases.detect { |phase| phase.name == "Fabric" }
    target.build_phases.delete(fabric_phase) if fabric_phase
  end
  project.save if project.dirty?
end

remove_fabric_from_project File.join(destination, 'Canvas', 'Canvas.xcodeproj')
remove_fabric_from_project File.join(destination, 'rn', 'Teacher', 'ios', 'Teacher.xcodeproj')

puts "Removing all sensitive data"
def remove_fabric_from_plist(plist_path)
  hash = Plist::parse_xml(plist_path)
  hash.delete 'Fabric'
  File.write(plist_path, hash.to_plist)
end

def prune_plist(plist_path)
  abort("File doesn't exist: #{plist_path}") unless File.exist?(plist_path)
  keys_hash = Plist::parse_xml(plist_path)
  keys_hash.each { |key, value| keys_hash[key] = '' }
  File.write(plist_path, keys_hash.to_plist)
end

def purge_plist(plist_path)
  keys_hash = Plist::parse_xml(plist_path)
  keys_hash.each { |key, value| keys_hash.delete key }
  File.write(plist_path, keys_hash.to_plist)
end

remove_fabric_from_plist File.join(destination, 'Canvas', 'Canvas', 'Info.plist')
remove_fabric_from_plist File.join(destination, 'rn', 'Teacher', 'ios', 'Teacher', 'Info.plist')

# Strip out all of the keys from our stuff, making an empty template file
prune_plist File.join(destination, 'secrets.plist')
prune_plist File.join(canvas_core_path, 'CanvasCore', 'Secrets', 'feature_toggles.plist')

opensource_files_dir    = File.join('opensource', 'files')
external_frameworks_dir = File.join(destination, 'ExternalFrameworks')

# Copy over the readme files
FileUtils.cp File.join(opensource_files_dir, 'README.md'), File.join(destination, 'README.md')
FileUtils.mkdir external_frameworks_dir unless File.exist? external_frameworks_dir
FileUtils.cp File.join(opensource_files_dir, 'EFREADME.md'), File.join(external_frameworks_dir, 'README.md')

# Remove PSPDFKit from ExternalFrameworks
pspdfkit_dir = File.join(external_frameworks_dir, 'PSPDFKit.framework')
FileUtils.rm_r pspdfkit_dir if File.exists? pspdfkit_dir

# Remove GoogleServices plist
google_services_path = File.join(destination, 'Canvas', 'Canvas', 'Shrug', 'GoogleService-Info.plist')
purge_plist google_services_path

# Remove Matchfile
FileUtils.rm File.join(destination, 'fastlane', 'Matchfile')
FileUtils.rm File.join(destination, 'fastlane', 'Appfile')

# Remove buddybuild scripts
FileUtils.rm File.join(destination, 'rn', 'Teacher', 'ios', 'buddybuild_postbuild.sh')
FileUtils.rm File.join(destination, 'rn', 'Teacher', 'ios', 'buddybuild_prebuild.sh')

# Remove folders from frameworks that shouldn't be there
frameworks_to_remove.each do |folder|
  FileUtils.rm_r File.join(frameworks_path, folder)
end

# Replace PSPDFKit stuff in Podfile

expires = Date.new(2018, 10, 1)
raise "Cannot update Podfile with the correct information. You need to renew the trial Podfile URL with PSPDFKit" unless expires > Date.today

podfile = File.open(podfile_path)
podfile_contents = File.read(podfile)
pspdfkit_license = "https://customers.pspdfkit.com/cocoapods/8YzxfVzsGsqs4HKYsejmoeD6WEJ9ma"
raise "Cannot update the Podfile with the correct PSPDFKit license" unless podfile_contents.include?(pspdfkit_license)
new_podfile_contents = podfile_contents.gsub(pspdfkit_license, "https://customers.pspdfkit.com/cocoapods/TRIAL-x47r57c_x_ndkkTGJ8Un-fmB8EXXDom1r2FSyQhPZEx2i2uQGGBjZnzJTJ_az2BccXySgrFZK3AwksivROwULg")
File.open(podfile, "w") {|file| file.puts new_podfile_contents }

puts "PRAISE THE SUN IT'S FINISHED"
