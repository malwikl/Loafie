require "xcodeproj"
require "fileutils"

project_path = "Loafie.xcodeproj"
project = Xcodeproj::Project.open(project_path)

ios_target = project.targets.find { |t| t.name == "Loafie" }
raise "iOS target not found" unless ios_target

# ---------------------------------------------------------------------------
# Live Activity extension group
# ---------------------------------------------------------------------------
la_group = project.main_group.new_group("LoafieLiveActivity", "LoafieLiveActivity")

# ---------------------------------------------------------------------------
# Live Activity extension target
# ---------------------------------------------------------------------------
la_target = project.new_target(
  :app_extension,
  "LoafieLiveActivity",
  :ios,
  "16.1",
  nil,
  :swift
)
la_target.build_configurations.each do |config|
  config.build_settings["PRODUCT_BUNDLE_IDENTIFIER"] = "de.kloeffer.loafies.liveactivity"
  config.build_settings["INFOPLIST_FILE"] = "LoafieLiveActivity/Info.plist"
  config.build_settings["PRODUCT_NAME"] = "$(TARGET_NAME)"
  config.build_settings["SDKROOT"] = "iphoneos"
  config.build_settings["SUPPORTED_PLATFORMS"] = "iphoneos iphonesimulator"
  config.build_settings["TARGETED_DEVICE_FAMILY"] = "1,2"
  config.build_settings["IPHONEOS_DEPLOYMENT_TARGET"] = "16.1"
  config.build_settings["GENERATE_INFOPLIST_FILE"] = "NO"
  config.build_settings["SWIFT_VERSION"] = "5.0"
  config.build_settings["CODE_SIGN_STYLE"] = "Automatic"
  config.build_settings["LD_RUNPATH_SEARCH_PATHS"] = "$(inherited) @executable_path/Frameworks @executable_path/../../Frameworks"
  config.build_settings["MARKETING_VERSION"] = "1.0"
  config.build_settings["CURRENT_PROJECT_VERSION"] = "1"
  config.build_settings["SKIP_INSTALL"] = "YES"
end

# ---------------------------------------------------------------------------
# Dependencies and embed phase
# ---------------------------------------------------------------------------
def create_embed_phase(project, target, product_ref, attributes)
  phase = project.new(Xcodeproj::Project::Object::PBXCopyFilesBuildPhase)
  phase.name = "Embed App Extensions"
  phase.dst_subfolder_spec = "16" # Plugins
  build_file = project.new(Xcodeproj::Project::Object::PBXBuildFile)
  build_file.file_ref = product_ref
  build_file.settings = { "ATTRIBUTES" => attributes } unless attributes.empty?
  phase.files << build_file
  target.build_phases << phase
  phase
end

ios_target.add_dependency(la_target)
la_embed = create_embed_phase(project, ios_target, la_target.product_reference, ["RemoveHeadersOnCopy"])

# ---------------------------------------------------------------------------
# Add files to targets
# ---------------------------------------------------------------------------
def add_files(target, group, paths, resource: false)
  refs = paths.map { |p| group.new_file(p) }
  if resource
    target.add_resources(refs)
  else
    target.add_file_references(refs)
  end
  refs
end

# Sources compiled only into the extension target
ext_sources = [
  "LoafieLiveActivityAttributes.swift",
  "LoafieLiveActivityBundle.swift",
  "LoafieLiveActivity.swift"
]
add_files(la_target, la_group, ext_sources, resource: false)

# Resources
add_files(la_target, la_group, ["Assets.xcassets"], resource: true)

# Shared attributes file also compiled into the main app target
shared_ref = la_group.new_file("LoafieLiveActivityAttributes.swift")
ios_target.add_file_references([shared_ref])

# ---------------------------------------------------------------------------
# Enable Live Activities on the main app target
# ---------------------------------------------------------------------------
ios_target.build_configurations.each do |config|
  config.build_settings["INFOPLIST_KEY_NSSupportsLiveActivities"] = "YES"
  config.build_settings["INFOPLIST_KEY_NSSupportsLiveActivitiesFrequentUpdates"] = "YES"
end

# ---------------------------------------------------------------------------
# Save
# ---------------------------------------------------------------------------
project.save
puts "Live Activity target added successfully."
