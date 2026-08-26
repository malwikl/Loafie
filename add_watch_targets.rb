require "xcodeproj"
require "fileutils"

project_path = "Loafie.xcodeproj"
project = Xcodeproj::Project.open(project_path)

ios_target = project.targets.find { |t| t.name == "Loafie" }
raise "iOS target not found" unless ios_target

# ---------------------------------------------------------------------------
# Groups (normal groups for the new targets)
# ---------------------------------------------------------------------------
watch_group = project.main_group.new_group("LoafieWatch", "LoafieWatch")
watch_ext_group = project.main_group.new_group("LoafieWatch Extension", "LoafieWatch Extension")

# ---------------------------------------------------------------------------
# Watch Extension target
# ---------------------------------------------------------------------------
ext_target = project.new_target(
  :watch2_extension,
  "LoafieWatch Extension",
  :watchos,
  "10.0",
  nil,
  :swift
)
ext_target.build_configurations.each do |config|
  config.build_settings["PRODUCT_BUNDLE_IDENTIFIER"] = "de.kloeffer.loafies.watchkitapp.watchkitextension"
  config.build_settings["INFOPLIST_FILE"] = "LoafieWatch Extension/Info.plist"
  config.build_settings["PRODUCT_NAME"] = "$(TARGET_NAME)"
  config.build_settings["SDKROOT"] = "watchos"
  config.build_settings["SUPPORTED_PLATFORMS"] = "watchos"
  config.build_settings["TARGETED_DEVICE_FAMILY"] = "4"
  config.build_settings["WATCHOS_DEPLOYMENT_TARGET"] = "10.0"
  config.build_settings["GENERATE_INFOPLIST_FILE"] = "NO"
  config.build_settings["SWIFT_VERSION"] = "5.0"
  config.build_settings["CODE_SIGN_STYLE"] = "Automatic"
  config.build_settings["LD_RUNPATH_SEARCH_PATHS"] = "$(inherited) @executable_path/Frameworks @executable_path/../../Frameworks"
  config.build_settings["MARKETING_VERSION"] = "1.0"
  config.build_settings["CURRENT_PROJECT_VERSION"] = "1"
  config.build_settings["SKIP_INSTALL"] = "YES"
end

# ---------------------------------------------------------------------------
# Watch App target
# ---------------------------------------------------------------------------
app_target = project.new_target(
  :watch2_app,
  "LoafieWatch",
  :watchos,
  "10.0",
  nil,
  :swift
)
app_target.build_configurations.each do |config|
  config.build_settings["PRODUCT_BUNDLE_IDENTIFIER"] = "de.kloeffer.loafies.watchkitapp"
  config.build_settings["INFOPLIST_FILE"] = "LoafieWatch/Info.plist"
  config.build_settings["PRODUCT_NAME"] = "$(TARGET_NAME)"
  config.build_settings["SDKROOT"] = "watchos"
  config.build_settings["SUPPORTED_PLATFORMS"] = "watchos"
  config.build_settings["TARGETED_DEVICE_FAMILY"] = "4"
  config.build_settings["WATCHOS_DEPLOYMENT_TARGET"] = "10.0"
  config.build_settings["ASSETCATALOG_COMPILER_APPICON_NAME"] = "AppIcon"
  config.build_settings["GENERATE_INFOPLIST_FILE"] = "NO"
  config.build_settings["SWIFT_VERSION"] = "5.0"
  config.build_settings["CODE_SIGN_STYLE"] = "Automatic"
  config.build_settings["MARKETING_VERSION"] = "1.0"
  config.build_settings["CURRENT_PROJECT_VERSION"] = "1"
  config.build_settings["SKIP_INSTALL"] = "NO"
end

# ---------------------------------------------------------------------------
# Dependencies and embed phases
# ---------------------------------------------------------------------------
def create_embed_phase(project, target, product_ref, attributes)
  phase = project.new(Xcodeproj::Project::Object::PBXCopyFilesBuildPhase)
  phase.name = "Embed"
  phase.dst_subfolder_spec = "16" # Plugins
  build_file = project.new(Xcodeproj::Project::Object::PBXBuildFile)
  build_file.file_ref = product_ref
  build_file.settings = { "ATTRIBUTES" => attributes } unless attributes.empty?
  phase.files << build_file
  target.build_phases << phase
  phase
end

# Watch app embeds the extension
app_target.add_dependency(ext_target)
ext_embed = create_embed_phase(project, app_target, ext_target.product_reference, ["RemoveHeadersOnCopy"])
ext_embed.name = "Embed App Extensions"

# iOS app embeds the watch app
ios_target.add_dependency(app_target)
watch_embed = create_embed_phase(project, ios_target, app_target.product_reference, ["CodeSignOnCopy"])
watch_embed.dst_subfolder_spec = "11" # Watch content
watch_embed.name = "Embed Watch Content"

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

# Extension sources
ext_sources = [
  "LoafieWatchApp.swift",
  "ContentView.swift",
  "WatchSessionModel.swift",
  "WatchSessionView.swift",
  "NoSessionView.swift",
  "WatchSessionSnapshot.swift"
]
add_files(ext_target, watch_ext_group, ext_sources, resource: false)

# Extension resources
add_files(ext_target, watch_ext_group, ["Assets.xcassets"], resource: true)

# Watch app resources
add_files(app_target, watch_group, ["Assets.xcassets"], resource: true)

# ---------------------------------------------------------------------------
# Save
# ---------------------------------------------------------------------------
project.save
puts "Watch targets added successfully."
