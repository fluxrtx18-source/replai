#!/usr/bin/env python3
"""
generate_xcodeproj.py
Generates ReplAI.xcodeproj from the source tree.
Run: python3 generate_xcodeproj.py
"""

import uuid, os
from pathlib import Path

BASE  = Path(__file__).parent
PROJ  = "ReplAI"

# ── UUID factory ───────────────────────────────────────────────────────────────
def uid():
    return uuid.uuid4().hex[:24].upper()

# ── All unique identifiers ─────────────────────────────────────────────────────
# IMPORTANT: target_app and target_ext are pinned to match the BlueprintIdentifier
# values in xcshareddata/xcschemes/ReplAI.xcscheme. If these randomise on every
# regeneration the scheme can no longer find the targets → StoreKit config stops
# being injected → Product.products(for:) returns [] → paywall shows no plans.
STABLE = {
    "target_app": "5543841856FFCBB316A18FF7",  # ReplAI target
    "target_ext": "794DA2A13F496AC8E724EAD4",  # ReplAIShareExtension target
}

I = {k: uid() for k in [
    # Project structure
    "project", "main_group", "products_group",
    "replai_group", "app_group", "design_group", "models_group",
    "services_group", "features_group", "home_group", "analysis_group",
    "paywall_group", "ext_group", "config_group",
    # Targets (overridden below with stable values)
    "target_app", "target_ext",
    # Products
    "product_app", "product_ext",
    # Config lists
    "proj_cfglist", "app_cfglist", "ext_cfglist",
    # Build configurations
    "proj_debug", "proj_release",
    "app_debug",  "app_release",
    "ext_debug",  "ext_release",
    # Build phases – app
    "app_sources", "app_frameworks", "app_resources", "app_copy_ext",
    # Build phases – extension
    "ext_sources", "ext_frameworks", "ext_resources",
    # Extension embed + dependency
    "ext_embed_bf", "ext_dep", "ext_proxy",
    # Non-source file references
    "app_entitlements_ref", "ext_entitlements_ref",
    "app_info_ref",         "ext_info_ref",
    "storekit_ref",         "storekit_resources_bf",
    # Localizable.xcstrings
    "xcstrings_ref", "xcstrings_app_bf", "xcstrings_ext_bf",
    # Assets.xcassets (app icon + colors)
    "assets_ref", "assets_app_bf",
    # Resources group in navigator
    "resources_group",
]}
I.update(STABLE)  # Pin scheme-referenced UUIDs so scheme stays valid across regenerations

# ── Source files ───────────────────────────────────────────────────────────────
# Each entry: path (relative to BASE), in_app, in_ext
SOURCES = [
    # App entry point
    ("ReplAI/App/ReplAIApp.swift",                                True,  False),
    # Design / constants (shared with ShareExtension)
    ("ReplAI/Design/AppDesign.swift",                             True,  True),
    # Models
    ("ReplAI/Models/ReplyTone.swift",                             True,  True),
    ("ReplAI/Models/ConversationAnalysis.swift",                  True,  False),
    ("ReplAI/Models/IdentifiableImage.swift",                     True,  False),
    # Services
    ("ReplAI/Services/VisionService.swift",                       True,  False),
    ("ReplAI/Services/AICoachService.swift",                      True,  False),
    ("ReplAI/Services/UsageTracker.swift",                        True,  False),
    ("ReplAI/Services/SubscriptionManager.swift",                 True,  False),
    # Home views
    ("ReplAI/Features/Home/HomeView.swift",                       True,  False),
    ("ReplAI/Features/Home/HomeHeaderView.swift",                 True,  False),
    ("ReplAI/Features/Home/HomeActionSection.swift",              True,  False),
    ("ReplAI/Features/Home/HowItWorksCard.swift",                 True,  False),
    ("ReplAI/Features/Home/StepRowView.swift",                    True,  False),
    ("ReplAI/Features/Home/UsageBadgeView.swift",                 True,  False),
    ("ReplAI/Features/Home/MainActionButton.swift",               True,  False),
    ("ReplAI/Features/Home/MainActionButtonLabel.swift",          True,  False),
    # Analysis views
    ("ReplAI/Features/Analysis/AnalysisViewModel.swift",          True,  False),
    ("ReplAI/Features/Analysis/AnalysisView.swift",               True,  False),
    ("ReplAI/Features/Analysis/AnalysisSummaryCard.swift",        True,  False),
    ("ReplAI/Features/Analysis/ReplyCardView.swift",              True,  False),
    ("ReplAI/Features/Analysis/LoadingView.swift",                True,  False),
    ("ReplAI/Features/Analysis/AnalysisResultsView.swift",        True,  False),
    ("ReplAI/Features/Analysis/AnalysisErrorView.swift",          True,  False),
    # Paywall views
    ("ReplAI/Features/Paywall/PaywallGate.swift",                 True,  False),
    ("ReplAI/Features/Paywall/PaywallViewModel.swift",            True,  False),
    ("ReplAI/Features/Paywall/PaywallView.swift",                 True,  False),
    ("ReplAI/Features/Paywall/PaywallHeaderView.swift",           True,  False),
    ("ReplAI/Features/Paywall/PaywallFeaturesCard.swift",         True,  False),
    ("ReplAI/Features/Paywall/FeatureRowView.swift",              True,  False),
    ("ReplAI/Features/Paywall/PlanRowView.swift",                 True,  False),
    ("ReplAI/Features/Paywall/PaywallFooterView.swift",           True,  False),
    # Share Extension (only AppDesign + ReplyTone shared from ReplAI/)
    ("ReplAIShareExtension/ShareViewController.swift",            False, True),
    ("ReplAIShareExtension/ShareView.swift",                      False, True),
]

# Attach UUIDs
files = []
for (path, in_app, in_ext) in SOURCES:
    f = {"path": path, "in_app": in_app, "in_ext": in_ext,
         "ref": uid(), "name": Path(path).name}
    if in_app: f["app_bf"] = uid()
    if in_ext: f["ext_bf"] = uid()
    files.append(f)

# ── Render helpers ─────────────────────────────────────────────────────────────
def q(s):
    """Quote a string if it contains spaces or special chars.
    Note: <> must be quoted because bare <...> in OpenStep plist is
    interpreted as binary hex data, not as a string.
    """
    if not s:
        return '""'
    needs = any(c in s for c in ' ()[]{},"=\\@+-<>')
    return f'"{s}"' if needs else s

def lst(items, indent="\t\t\t\t"):
    if not items:
        return "()"
    body = (",\n" + indent).join(items)
    return f"(\n{indent}{body},\n{indent[:-1]})"

def settings_block(d, indent="\t\t\t\t"):
    if not d:
        return "{}"
    lines = ["{"]
    for k, v in d.items():
        lines.append(f"{indent}{k} = {q(v) if isinstance(v, str) else v};")
    lines.append(f"{indent[:-1]}{'}'}")
    return "\n".join(lines)

# ── Section builders ───────────────────────────────────────────────────────────
def section(name, entries):
    return (
        f"\n/* Begin {name} section */\n"
        + "".join(entries)
        + f"/* End {name} section */\n"
    )

def obj(uid_val, comment, body):
    return f"\t\t{uid_val} /* {comment} */ = {{{body}\t\t}};\n"

# ── PBXBuildFile ──────────────────────────────────────────────────────────────
def build_file_entries():
    out = []
    for f in files:
        name = f["name"]
        if f["in_app"]:
            out.append(f'\t\t{f["app_bf"]} /* {name} in Sources */ = '
                       f'{{isa = PBXBuildFile; fileRef = {f["ref"]} /* {name} */; }};\n')
        if f["in_ext"]:
            out.append(f'\t\t{f["ext_bf"]} /* {name} in Sources */ = '
                       f'{{isa = PBXBuildFile; fileRef = {f["ref"]} /* {name} */; }};\n')

    # Extension embed build file
    out.append(f'\t\t{I["ext_embed_bf"]} /* ReplAIShareExtension.appex in Embed Foundation Extensions */ = '
               f'{{isa = PBXBuildFile; fileRef = {I["product_ext"]} /* ReplAIShareExtension.appex */; '
               f'settings = {{ATTRIBUTES = (RemoveHeadersOnCopy, ); }}; }};\n')
    # Assets.xcassets in resources
    out.append(f'\t\t{I["assets_app_bf"]} /* Assets.xcassets in Resources */ = '
               f'{{isa = PBXBuildFile; fileRef = {I["assets_ref"]} /* Assets.xcassets */; }};\n')
    # StoreKit config in resources
    out.append(f'\t\t{I["storekit_resources_bf"]} /* StoreKit.storekit in Resources */ = '
               f'{{isa = PBXBuildFile; fileRef = {I["storekit_ref"]} /* StoreKit.storekit */; }};\n')
    # Localizable.xcstrings in resources (app + extension)
    out.append(f'\t\t{I["xcstrings_app_bf"]} /* Localizable.xcstrings in Resources */ = '
               f'{{isa = PBXBuildFile; fileRef = {I["xcstrings_ref"]} /* Localizable.xcstrings */; }};\n')
    out.append(f'\t\t{I["xcstrings_ext_bf"]} /* Localizable.xcstrings in Resources */ = '
               f'{{isa = PBXBuildFile; fileRef = {I["xcstrings_ref"]} /* Localizable.xcstrings */; }};\n')
    return out

# ── PBXContainerItemProxy ─────────────────────────────────────────────────────
def proxy_entries():
    body = (f"\n\t\t\tisa = PBXContainerItemProxy;\n"
            f"\t\t\tcontainerPortal = {I['project']} /* Project object */;\n"
            f"\t\t\tproxyType = 1;\n"
            f"\t\t\tremoteGlobalIDString = {I['target_ext']};\n"
            f"\t\t\tremoteInfo = ReplAIShareExtension;\n")
    return [obj(I["ext_proxy"], "PBXContainerItemProxy", body)]

# ── PBXCopyFilesBuildPhase ────────────────────────────────────────────────────
def copy_phase_entries():
    body = (f"\n\t\t\tisa = PBXCopyFilesBuildPhase;\n"
            f"\t\t\tbuildActionMask = 2147483647;\n"
            f"\t\t\tdstPath = \"\";\n"
            f"\t\t\tdstSubfolderSpec = 13;\n"
            f"\t\t\tfiles = (\n"
            f"\t\t\t\t{I['ext_embed_bf']} /* ReplAIShareExtension.appex in Embed Foundation Extensions */,\n"
            f"\t\t\t);\n"
            f"\t\t\tname = \"Embed Foundation Extensions\";\n"
            f"\t\t\trunOnlyForDeploymentPostprocessing = 0;\n")
    return [obj(I["app_copy_ext"], "Embed Foundation Extensions", body)]

# ── PBXFileReference ──────────────────────────────────────────────────────────
def file_ref_entries():
    out = []
    for f in files:
        out.append(f'\t\t{f["ref"]} /* {f["name"]} */ = '
                   f'{{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; '
                   f'path = {q(f["name"])}; sourceTree = "<group>"; }};\n')

    # Products
    out.append(f'\t\t{I["product_app"]} /* ReplAI.app */ = '
               f'{{isa = PBXFileReference; explicitFileType = wrapper.application; '
               f'includeInIndex = 0; path = ReplAI.app; sourceTree = BUILT_PRODUCTS_DIR; }};\n')
    out.append(f'\t\t{I["product_ext"]} /* ReplAIShareExtension.appex */ = '
               f'{{isa = PBXFileReference; explicitFileType = "com.apple.product-type.app-extension"; '
               f'includeInIndex = 0; path = ReplAIShareExtension.appex; sourceTree = BUILT_PRODUCTS_DIR; }};\n')

    # Entitlements
    out.append(f'\t\t{I["app_entitlements_ref"]} /* ReplAI.entitlements */ = '
               f'{{isa = PBXFileReference; lastKnownFileType = text.plist.entitlements; '
               f'path = ReplAI.entitlements; sourceTree = "<group>"; }};\n')
    out.append(f'\t\t{I["ext_entitlements_ref"]} /* ReplAIShareExtension.entitlements */ = '
               f'{{isa = PBXFileReference; lastKnownFileType = text.plist.entitlements; '
               f'path = ReplAIShareExtension.entitlements; sourceTree = "<group>"; }};\n')

    # Info.plists
    out.append(f'\t\t{I["app_info_ref"]} /* Info.plist */ = '
               f'{{isa = PBXFileReference; lastKnownFileType = text.plist.xml; '
               f'path = Info.plist; sourceTree = "<group>"; }};\n')
    out.append(f'\t\t{I["ext_info_ref"]} /* Info.plist */ = '
               f'{{isa = PBXFileReference; lastKnownFileType = text.plist.xml; '
               f'path = Info.plist; sourceTree = "<group>"; }};\n')

    # StoreKit config
    out.append(f'\t\t{I["storekit_ref"]} /* StoreKit.storekit */ = '
               f'{{isa = PBXFileReference; lastKnownFileType = text; '
               f'path = StoreKit.storekit; sourceTree = "<group>"; }};\n')

    # Localizable.xcstrings
    out.append(f'\t\t{I["xcstrings_ref"]} /* Localizable.xcstrings */ = '
               f'{{isa = PBXFileReference; lastKnownFileType = text.plist.xcstrings; '
               f'path = Localizable.xcstrings; sourceTree = "<group>"; }};\n')

    # Assets.xcassets
    out.append(f'\t\t{I["assets_ref"]} /* Assets.xcassets */ = '
               f'{{isa = PBXFileReference; lastKnownFileType = folder.assetcatalog; '
               f'path = Assets.xcassets; sourceTree = "<group>"; }};\n')

    return out

# ── PBXFrameworksBuildPhase ───────────────────────────────────────────────────
def frameworks_entries():
    def phase(uid_val, comment):
        body = (f"\n\t\t\tisa = PBXFrameworksBuildPhase;\n"
                f"\t\t\tbuildActionMask = 2147483647;\n"
                f"\t\t\tfiles = (\n\t\t\t);\n"
                f"\t\t\trunOnlyForDeploymentPostprocessing = 0;\n")
        return obj(uid_val, comment, body)
    return [
        phase(I["app_frameworks"], "Frameworks"),
        phase(I["ext_frameworks"], "Frameworks"),
    ]

# ── PBXGroup ──────────────────────────────────────────────────────────────────
def group(uid_val, name, children, path=None, source_tree="<group>"):
    child_lines = "".join(
        f"\t\t\t\t{c_uid} /* {c_name} */,\n"
        for c_uid, c_name in children
    )
    path_line = f"\t\t\tpath = {q(path)};\n" if path else ""
    body = (f"\n\t\t\tisa = PBXGroup;\n"
            f"\t\t\tchildren = (\n{child_lines}\t\t\t);\n"
            f"{path_line}"
            f"\t\t\tsourceTree = {q(source_tree)};\n")
    if not path:
        body += f"\t\t\tname = {q(name)};\n" if name else ""
    return obj(uid_val, name, body)

def group_entries():
    out = []

    # Leaf groups ──
    files_by_folder = {}
    for f in files:
        folder = str(Path(f["path"]).parent)
        files_by_folder.setdefault(folder, []).append(f)

    def srcs(folder):
        return [(f["ref"], f["name"]) for f in files_by_folder.get(folder, [])]

    out.append(group(I["app_group"], "App",
                     srcs("ReplAI/App") + [(I["app_info_ref"], "Info.plist")],
                     path="App"))
    out.append(group(I["design_group"], "Design",
                     srcs("ReplAI/Design"), path="Design"))
    out.append(group(I["models_group"], "Models",
                     srcs("ReplAI/Models"), path="Models"))
    out.append(group(I["services_group"], "Services",
                     srcs("ReplAI/Services"), path="Services"))
    out.append(group(I["home_group"], "Home",
                     srcs("ReplAI/Features/Home"), path="Home"))
    out.append(group(I["analysis_group"], "Analysis",
                     srcs("ReplAI/Features/Analysis"), path="Analysis"))
    out.append(group(I["paywall_group"], "Paywall",
                     srcs("ReplAI/Features/Paywall"), path="Paywall"))
    out.append(group(I["features_group"], "Features", [
        (I["home_group"],     "Home"),
        (I["analysis_group"], "Analysis"),
        (I["paywall_group"],  "Paywall"),
    ], path="Features"))

    # Resources group (asset catalog lives in ReplAI/Resources/)
    out.append(group(I["resources_group"], "Resources",
                     [(I["assets_ref"], "Assets.xcassets")],
                     path="Resources"))

    # ReplAI group
    out.append(group(I["replai_group"], "ReplAI", [
        (I["app_group"],        "App"),
        (I["design_group"],     "Design"),
        (I["models_group"],     "Models"),
        (I["services_group"],   "Services"),
        (I["features_group"],   "Features"),
        (I["resources_group"],  "Resources"),
        (I["xcstrings_ref"],    "Localizable.xcstrings"),
    ], path="ReplAI"))

    # Extension group
    out.append(group(I["ext_group"], "ReplAIShareExtension",
                     srcs("ReplAIShareExtension") + [(I["ext_info_ref"], "Info.plist")],
                     path="ReplAIShareExtension"))

    # Configuration group
    out.append(group(I["config_group"], "Configuration", [
        (I["app_entitlements_ref"], "ReplAI.entitlements"),
        (I["ext_entitlements_ref"], "ReplAIShareExtension.entitlements"),
        (I["storekit_ref"],         "StoreKit.storekit"),
    ], path="Configuration"))

    # Products group
    out.append(group(I["products_group"], "Products", [
        (I["product_app"], "ReplAI.app"),
        (I["product_ext"], "ReplAIShareExtension.appex"),
    ]))

    # Root / main group
    out.append(group(I["main_group"], "", [
        (I["replai_group"],    "ReplAI"),
        (I["ext_group"],       "ReplAIShareExtension"),
        (I["config_group"],    "Configuration"),
        (I["products_group"],  "Products"),
    ]))

    return out

# ── PBXNativeTarget ───────────────────────────────────────────────────────────
def native_target_entries():
    out = []

    # App target
    body = (f"\n\t\t\tisa = PBXNativeTarget;\n"
            f"\t\t\tbuildConfigurationList = {I['app_cfglist']} "
            f"/* Build configuration list for PBXNativeTarget \"{PROJ}\" */;\n"
            f"\t\t\tbuildPhases = (\n"
            f"\t\t\t\t{I['app_sources']} /* Sources */,\n"
            f"\t\t\t\t{I['app_frameworks']} /* Frameworks */,\n"
            f"\t\t\t\t{I['app_resources']} /* Resources */,\n"
            f"\t\t\t\t{I['app_copy_ext']} /* Embed Foundation Extensions */,\n"
            f"\t\t\t);\n"
            f"\t\t\tbuildRules = (\n\t\t\t);\n"
            f"\t\t\tdependencies = (\n"
            f"\t\t\t\t{I['ext_dep']} /* PBXTargetDependency */,\n"
            f"\t\t\t);\n"
            f"\t\t\tname = {PROJ};\n"
            f"\t\t\tproductName = {PROJ};\n"
            f"\t\t\tproductReference = {I['product_app']} /* ReplAI.app */;\n"
            f"\t\t\tproductType = \"com.apple.product-type.application\";\n")
    out.append(obj(I["target_app"], PROJ, body))

    # Extension target
    body = (f"\n\t\t\tisa = PBXNativeTarget;\n"
            f"\t\t\tbuildConfigurationList = {I['ext_cfglist']} "
            f"/* Build configuration list for PBXNativeTarget \"ReplAIShareExtension\" */;\n"
            f"\t\t\tbuildPhases = (\n"
            f"\t\t\t\t{I['ext_sources']} /* Sources */,\n"
            f"\t\t\t\t{I['ext_frameworks']} /* Frameworks */,\n"
            f"\t\t\t\t{I['ext_resources']} /* Resources */,\n"
            f"\t\t\t);\n"
            f"\t\t\tbuildRules = (\n\t\t\t);\n"
            f"\t\t\tdependencies = (\n\t\t\t);\n"
            f"\t\t\tname = ReplAIShareExtension;\n"
            f"\t\t\tproductName = ReplAIShareExtension;\n"
            f"\t\t\tproductReference = {I['product_ext']} /* ReplAIShareExtension.appex */;\n"
            f"\t\t\tproductType = \"com.apple.product-type.app-extension\";\n")
    out.append(obj(I["target_ext"], "ReplAIShareExtension", body))
    return out

# ── PBXProject ────────────────────────────────────────────────────────────────
def project_entry():
    body = (f"\n\t\t\tisa = PBXProject;\n"
            f"\t\t\tattributes = {{\n"
            f"\t\t\t\tBuildIndependentTargetsInParallel = 1;\n"
            f"\t\t\t\tLastSwiftUpdateCheck = 1630;\n"
            f"\t\t\t\tLastUpgradeCheck = 1630;\n"
            f"\t\t\t\tTargetAttributes = {{\n"
            f"\t\t\t\t\t{I['target_app']} = {{\n"
            f"\t\t\t\t\t\tCreatedOnToolsVersion = 16.3;\n"
            f"\t\t\t\t\t}};\n"
            f"\t\t\t\t\t{I['target_ext']} = {{\n"
            f"\t\t\t\t\t\tCreatedOnToolsVersion = 16.3;\n"
            f"\t\t\t\t\t}};\n"
            f"\t\t\t\t}};\n"
            f"\t\t\t}};\n"
            f"\t\t\tbuildConfigurationList = {I['proj_cfglist']} "
            f"/* Build configuration list for PBXProject \"{PROJ}\" */;\n"
            f"\t\t\tcompatibilityVersion = \"Xcode 14.0\";\n"
            f"\t\t\tdevelopmentRegion = en;\n"
            f"\t\t\thasScannedForEncodings = 0;\n"
            f"\t\t\tknownRegions = (\n\t\t\t\ten,\n\t\t\t\tBase,\n\t\t\t\tde,\n\t\t\t\tes,\n\t\t\t\tfr,\n\t\t\t\tit,\n\t\t\t\tpt,\n\t\t\t);\n"
            f"\t\t\tmainGroup = {I['main_group']};\n"
            f"\t\t\tproductRefGroup = {I['products_group']} /* Products */;\n"
            f"\t\t\tprojectDirPath = \"\";\n"
            f"\t\t\tprojectRoot = \"\";\n"
            f"\t\t\ttargets = (\n"
            f"\t\t\t\t{I['target_app']} /* {PROJ} */,\n"
            f"\t\t\t\t{I['target_ext']} /* ReplAIShareExtension */,\n"
            f"\t\t\t);\n")
    return [obj(I["project"], "Project object", body)]

# ── PBXResourcesBuildPhase ────────────────────────────────────────────────────
def resources_entries():
    def phase(uid_val, comment, extra_files=""):
        body = (f"\n\t\t\tisa = PBXResourcesBuildPhase;\n"
                f"\t\t\tbuildActionMask = 2147483647;\n"
                f"\t\t\tfiles = (\n{extra_files}\t\t\t);\n"
                f"\t\t\trunOnlyForDeploymentPostprocessing = 0;\n")
        return obj(uid_val, comment, body)
    assets_line        = f"\t\t\t\t{I['assets_app_bf']} /* Assets.xcassets in Resources */,\n"
    storekit_line      = f"\t\t\t\t{I['storekit_resources_bf']} /* StoreKit.storekit in Resources */,\n"
    xcstrings_app_line = f"\t\t\t\t{I['xcstrings_app_bf']} /* Localizable.xcstrings in Resources */,\n"
    xcstrings_ext_line = f"\t\t\t\t{I['xcstrings_ext_bf']} /* Localizable.xcstrings in Resources */,\n"
    return [
        phase(I["app_resources"], "Resources", assets_line + storekit_line + xcstrings_app_line),
        phase(I["ext_resources"], "Resources", xcstrings_ext_line),
    ]

# ── PBXSourcesBuildPhase ──────────────────────────────────────────────────────
def sources_entries():
    app_lines = "".join(
        f"\t\t\t\t{f['app_bf']} /* {f['name']} in Sources */,\n"
        for f in files if f["in_app"]
    )
    ext_lines = "".join(
        f"\t\t\t\t{f['ext_bf']} /* {f['name']} in Sources */,\n"
        for f in files if f["in_ext"]
    )

    def phase(uid_val, comment, file_lines):
        body = (f"\n\t\t\tisa = PBXSourcesBuildPhase;\n"
                f"\t\t\tbuildActionMask = 2147483647;\n"
                f"\t\t\tfiles = (\n{file_lines}\t\t\t);\n"
                f"\t\t\trunOnlyForDeploymentPostprocessing = 0;\n")
        return obj(uid_val, comment, body)

    return [
        phase(I["app_sources"], "Sources", app_lines),
        phase(I["ext_sources"], "Sources", ext_lines),
    ]

# ── PBXTargetDependency ───────────────────────────────────────────────────────
def target_dep_entries():
    body = (f"\n\t\t\tisa = PBXTargetDependency;\n"
            f"\t\t\ttarget = {I['target_ext']} /* ReplAIShareExtension */;\n"
            f"\t\t\ttargetProxy = {I['ext_proxy']} /* PBXContainerItemProxy */;\n")
    return [obj(I["ext_dep"], "PBXTargetDependency", body)]

# ── XCBuildConfiguration ──────────────────────────────────────────────────────
PROJ_DEBUG_SETTINGS = {
    "ALWAYS_SEARCH_USER_PATHS": "NO",
    "CLANG_ANALYZER_NONNULL": "YES",
    "CLANG_ANALYZER_NUMBER_OBJECT_CONVERSION": "YES_AGGRESSIVE",
    "CLANG_CXX_LANGUAGE_STANDARD": "gnu++20",
    "CLANG_ENABLE_MODULES": "YES",
    "CLANG_ENABLE_OBJC_ARC": "YES",
    "CLANG_ENABLE_OBJC_WEAK": "YES",
    "CLANG_WARN_BLOCK_CAPTURE_AUTORELEASING": "YES",
    "CLANG_WARN_BOOL_CONVERSION": "YES",
    "CLANG_WARN_COMMA": "YES",
    "CLANG_WARN_CONSTANT_CONVERSION": "YES",
    "CLANG_WARN_DEPRECATED_OBJC_IMPLEMENTATIONS": "YES",
    "CLANG_WARN_DIRECT_OBJC_ISA_USAGE": "YES_ERROR",
    "CLANG_WARN_EMPTY_BODY": "YES",
    "CLANG_WARN_ENUM_CONVERSION": "YES",
    "CLANG_WARN_INFINITE_RECURSION": "YES",
    "CLANG_WARN_INT_CONVERSION": "YES",
    "CLANG_WARN_NON_LITERAL_NULL_CONVERSION": "YES",
    "CLANG_WARN_OBJC_IMPLICIT_RETAIN_SELF": "YES",
    "CLANG_WARN_OBJC_LITERAL_CONVERSION": "YES",
    "CLANG_WARN_OBJC_ROOT_CLASS": "YES_ERROR",
    "CLANG_WARN_QUOTED_INCLUDE_IN_FRAMEWORK_HEADER": "YES",
    "CLANG_WARN_RANGE_LOOP_ANALYSIS": "YES",
    "CLANG_WARN_STRICT_PROTOTYPES": "YES",
    "CLANG_WARN_SUSPICIOUS_MOVE": "YES",
    "CLANG_WARN_UNGUARDED_AVAILABILITY": "YES_AGGRESSIVE",
    "CLANG_WARN_UNREACHABLE_CODE": "YES",
    "CLANG_WARN__DUPLICATE_METHOD_MATCH": "YES",
    "COPY_PHASE_STRIP": "NO",
    "DEBUG_INFORMATION_FORMAT": "dwarf",
    "ENABLE_STRICT_OBJC_MSGSEND": "YES",
    "ENABLE_TESTABILITY": "YES",
    "GCC_C_LANGUAGE_STANDARD": "gnu17",
    "GCC_DYNAMIC_NO_PIC": "NO",
    "GCC_NO_COMMON_BLOCKS": "YES",
    "GCC_OPTIMIZATION_LEVEL": "0",
    "GCC_PREPROCESSOR_DEFINITIONS": "(\"DEBUG=1\", \"$(inherited)\")",
    "GCC_WARN_64_TO_32_BIT_CONVERSION": "YES",
    "GCC_WARN_ABOUT_RETURN_TYPE": "YES_ERROR",
    "GCC_WARN_UNDECLARED_SELECTOR": "YES",
    "GCC_WARN_UNINITIALIZED_AUTOS": "YES_AGGRESSIVE",
    "GCC_WARN_UNUSED_FUNCTION": "YES",
    "GCC_WARN_UNUSED_VARIABLE": "YES",
    "IPHONEOS_DEPLOYMENT_TARGET": "26.0",
    "MTL_ENABLE_DEBUG_INFO": "INCLUDE_SOURCE",
    "MTL_FAST_MATH": "YES",
    "ONLY_ACTIVE_ARCH": "YES",
    "SDKROOT": "iphoneos",
    "SWIFT_ACTIVE_COMPILATION_CONDITIONS": "DEBUG",
    "SWIFT_OPTIMIZATION_LEVEL": "-Onone",
}

PROJ_RELEASE_SETTINGS = {k: v for k, v in PROJ_DEBUG_SETTINGS.items()}
PROJ_RELEASE_SETTINGS.update({
    "DEBUG_INFORMATION_FORMAT": "dwarf-with-dsym",
    "ENABLE_NS_ASSERTIONS": "NO",
    "GCC_PREPROCESSOR_DEFINITIONS": "(\"$(inherited)\")",
    "MTL_ENABLE_DEBUG_INFO": "NO",
    "ONLY_ACTIVE_ARCH": "NO",
    "SWIFT_ACTIVE_COMPILATION_CONDITIONS": "",
    "SWIFT_COMPILATION_MODE": "wholemodule",
    "SWIFT_OPTIMIZATION_LEVEL": "-O",
    "VALIDATE_PRODUCT": "YES",
})

APP_COMMON = {
    "ASSETCATALOG_COMPILER_APPICON_NAME": "AppIcon",
    "CODE_SIGN_ENTITLEMENTS": "Configuration/ReplAI.entitlements",
    "CODE_SIGN_STYLE": "Automatic",
    "CURRENT_PROJECT_VERSION": "1",
    "DEVELOPMENT_TEAM": "RS8JSBN29A",
    "GENERATE_INFOPLIST_FILE": "NO",
    "INFOPLIST_FILE": "ReplAI/App/Info.plist",
    "IPHONEOS_DEPLOYMENT_TARGET": "26.0",
    "LD_RUNPATH_SEARCH_PATHS": "(\"$(inherited)\", \"@executable_path/Frameworks\")",
    "MARKETING_VERSION": "1.0",
    "PRODUCT_BUNDLE_IDENTIFIER": "com.huseyinataseven.replai",
    "PRODUCT_NAME": "$(TARGET_NAME)",
    "SWIFT_EMIT_LOC_STRINGS": "YES",
    "SWIFT_STRICT_CONCURRENCY": "complete",
    "SWIFT_VERSION": "6.0",
    "TARGETED_DEVICE_FAMILY": "1",
}

EXT_COMMON = {
    "CODE_SIGN_ENTITLEMENTS": "Configuration/ReplAIShareExtension.entitlements",
    "CODE_SIGN_STYLE": "Automatic",
    "CURRENT_PROJECT_VERSION": "1",
    "DEVELOPMENT_TEAM": "RS8JSBN29A",
    "GENERATE_INFOPLIST_FILE": "NO",
    "INFOPLIST_FILE": "ReplAIShareExtension/Info.plist",
    "IPHONEOS_DEPLOYMENT_TARGET": "26.0",
    "LD_RUNPATH_SEARCH_PATHS": "(\"$(inherited)\", \"@executable_path/../../Frameworks\")",
    "MARKETING_VERSION": "1.0",
    "PRODUCT_BUNDLE_IDENTIFIER": "com.huseyinataseven.replai.shareextension",
    "PRODUCT_NAME": "$(TARGET_NAME)",
    "SKIP_INSTALL": "YES",
    "SWIFT_EMIT_LOC_STRINGS": "YES",
    "SWIFT_STRICT_CONCURRENCY": "complete",
    "SWIFT_VERSION": "6.0",
    "TARGETED_DEVICE_FAMILY": "1",
}

def build_config(uid_val, name, settings):
    def qv(v):
        """Quote a setting value; preserve OpenStep list literals unchanged."""
        if v.startswith('('):   # already an OpenStep list – leave as-is
            return v
        return q(v)
    lines = "".join(f"\t\t\t\t{k} = {qv(v)};\n" for k, v in settings.items())
    body = (f"\n\t\t\tisa = XCBuildConfiguration;\n"
            f"\t\t\tbuildSettings = {{\n{lines}\t\t\t}};\n"
            f"\t\t\tname = {name};\n")
    return obj(uid_val, name, body)

def build_config_entries():
    out = []
    out.append(build_config(I["proj_debug"],   "Debug",   PROJ_DEBUG_SETTINGS))
    out.append(build_config(I["proj_release"], "Release", PROJ_RELEASE_SETTINGS))
    # Debug-only extras: expose StoreKitTest.framework so that the #if DEBUG
    # SKTestSession import in ReplAIApp.swift compiles without errors.
    # $(PLATFORM_DIR)/Developer/Library/Frameworks is where Xcode stores
    # developer-SDK-only frameworks like StoreKitTest (not in the regular iOS SDK).
    # -weak_framework makes the link optional so an absent framework at runtime
    # (e.g. archived Release build) never causes a crash.
    APP_DEBUG_EXTRA = {
        "FRAMEWORK_SEARCH_PATHS":
            "(\"$(inherited)\", \"$(PLATFORM_DIR)/Developer/Library/Frameworks\")",
        "OTHER_LDFLAGS":
            "(\"$(inherited)\", \"-weak_framework\", StoreKitTest)",
    }
    app_debug   = {**PROJ_DEBUG_SETTINGS,   **APP_COMMON, **APP_DEBUG_EXTRA}
    app_release = {**PROJ_RELEASE_SETTINGS, **APP_COMMON}
    out.append(build_config(I["app_debug"],    "Debug",   app_debug))
    out.append(build_config(I["app_release"],  "Release", app_release))
    ext_debug   = {**PROJ_DEBUG_SETTINGS,   **EXT_COMMON}
    ext_release = {**PROJ_RELEASE_SETTINGS, **EXT_COMMON}
    out.append(build_config(I["ext_debug"],    "Debug",   ext_debug))
    out.append(build_config(I["ext_release"],  "Release", ext_release))
    return out

# ── XCConfigurationList ───────────────────────────────────────────────────────
def config_list(uid_val, comment, debug_id, release_id, default_cfg="Release"):
    body = (f"\n\t\t\tisa = XCConfigurationList;\n"
            f"\t\t\tbuildConfigurations = (\n"
            f"\t\t\t\t{debug_id} /* Debug */,\n"
            f"\t\t\t\t{release_id} /* Release */,\n"
            f"\t\t\t);\n"
            f"\t\t\tdefaultConfigurationIsVisible = 0;\n"
            f"\t\t\tdefaultConfigurationName = {default_cfg};\n")
    return obj(uid_val, comment, body)

def config_list_entries():
    return [
        config_list(I["proj_cfglist"], f'Build configuration list for PBXProject "{PROJ}"',
                    I["proj_debug"], I["proj_release"]),
        config_list(I["app_cfglist"],  f'Build configuration list for PBXNativeTarget "{PROJ}"',
                    I["app_debug"],  I["app_release"]),
        config_list(I["ext_cfglist"],  'Build configuration list for PBXNativeTarget "ReplAIShareExtension"',
                    I["ext_debug"],  I["ext_release"]),
    ]

# ── Assemble ───────────────────────────────────────────────────────────────────
def build_pbxproj():
    parts = [
        "// !$*UTF8*$!\n{\n"
        "\tarchiveVersion = 1;\n"
        "\tclasses = {\n\t};\n"
        "\tobjectVersion = 77;\n"
        "\tobjects = {\n",
        section("PBXBuildFile",            build_file_entries()),
        section("PBXContainerItemProxy",   proxy_entries()),
        section("PBXCopyFilesBuildPhase",  copy_phase_entries()),
        section("PBXFileReference",        file_ref_entries()),
        section("PBXFrameworksBuildPhase", frameworks_entries()),
        section("PBXGroup",                group_entries()),
        section("PBXNativeTarget",         native_target_entries()),
        section("PBXProject",              project_entry()),
        section("PBXResourcesBuildPhase",  resources_entries()),
        section("PBXSourcesBuildPhase",    sources_entries()),
        section("PBXTargetDependency",     target_dep_entries()),
        section("XCBuildConfiguration",    build_config_entries()),
        section("XCConfigurationList",     config_list_entries()),
        f"\t}};\n\trootObject = {I['project']} /* Project object */;\n}}\n",
    ]
    return "".join(parts)

# ── Write files ────────────────────────────────────────────────────────────────
def write_xcodeproj():
    xcproj = BASE / f"{PROJ}.xcodeproj"
    xcproj.mkdir(exist_ok=True)

    # project.pbxproj
    pbx = xcproj / "project.pbxproj"
    pbx.write_text(build_pbxproj(), encoding="utf-8")
    print(f"  ✔  {pbx}")

    # project.xcworkspace
    ws = xcproj / "project.xcworkspace"
    ws.mkdir(exist_ok=True)
    contents = ws / "contents.xcworkspacedata"
    contents.write_text(
        '<?xml version="1.0" encoding="UTF-8"?>\n'
        '<Workspace version = "1.0">\n'
        '   <FileRef location = "self:"></FileRef>\n'
        '</Workspace>\n',
        encoding="utf-8",
    )
    print(f"  ✔  {contents}")

if __name__ == "__main__":
    print(f"Generating {PROJ}.xcodeproj …")
    write_xcodeproj()
    print("Done. Open ReplAI.xcodeproj in Xcode.")
