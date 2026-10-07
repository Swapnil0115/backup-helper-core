import Foundation

public enum JunkReason: String, Codable, Hashable, Sendable, CaseIterable {
    case systemFile
    case codeProject
    case appData
    case linkPreview
    case thumbnailCache
    case sticker
    case deletedOnDevice
    case tinyImage

    public var label: String {
        switch self {
        case .systemFile: return "Hidden system file"
        case .codeProject: return "Image inside a code project"
        case .appData: return "App cache or app data"
        case .linkPreview: return "Chat link preview"
        case .thumbnailCache: return "Thumbnail cache"
        case .sticker: return "Chat sticker"
        case .deletedOnDevice: return "In the phone's trash"
        case .tinyImage: return "Icon-sized image"
        }
    }
}

/// Flags files that are almost certainly not personal photos. Junk is a suggestion shown to the
/// user in its own section, never a reason to hide or delete anything.
public struct JunkClassifier: Sendable {
    /// Images whose longest side is below this many pixels count as icons.
    public var tinyImageLimit: Int

    public init(tinyImageLimit: Int = 200) {
        self.tinyImageLimit = tinyImageLimit
    }

    /// A folder holding one of these is treated as the root of a code project.
    public static let projectMarkerFiles: Set<String> = [
        "package.json", "requirements.txt", "setup.py", "pyproject.toml", "manage.py", "pom.xml",
        "build.gradle", "build.gradle.kts", "cargo.toml", "go.mod", "gemfile", "composer.json",
        "makefile", "cmakelists.txt", ".gitignore", "androidmanifest.xml", "podfile",
    ]
    public static let projectMarkerExtensions: Set<String> = ["sln", "csproj", "vcxproj", "ipynb"]

    static let codeFolders: Set<String> = [
        "node_modules", "site-packages", "dist-packages", "__pycache__", ".git", "venv", ".venv",
        "bower_components", ".gradle", ".idea", ".vscode", "deriveddata", "pods",
    ]
    static let thumbnailFolders: Set<String> = [".thumbnails", "thumbnails", ".thumbs", "thumbs"]
    static let trashFolders: Set<String> = [".trash", ".trashed", ".recycle"]
    static let cacheFolders: Set<String> = ["cache", "caches", ".cache"]

    /// - Parameter projectRoots: lower-cased relative folders that contain a project marker.
    public func classify(relativePath: String, kind: MediaKind, metadata: EmbeddedMetadata?, projectRoots: Set<String>) -> JunkReason? {
        let components = relativePath.lowercased().split(separator: "/").map(String.init)
        guard let name = components.last else { return nil }
        let folders = Array(components.dropLast())

        if name.hasPrefix("._") { return .systemFile }
        if name.hasPrefix(".trashed-") || folders.contains(where: { Self.trashFolders.contains($0) }) {
            return .deletedOnDevice
        }
        if folders.contains(where: { Self.codeFolders.contains($0) || $0.hasSuffix(".xcassets") || $0.hasPrefix("drawable") || $0.hasPrefix("mipmap-") }) {
            return .codeProject
        }
        if isInsideProject(folders, projectRoots) { return .codeProject }
        if folders.contains(".links") { return .linkPreview }
        if folders.contains(where: { Self.thumbnailFolders.contains($0) }) { return .thumbnailCache }
        if folders.contains(where: { $0.contains("sticker") }) { return .sticker }
        if isAppData(folders) { return .appData }
        if kind == .photo, let size = metadata?.pixelSize, size.longestSide > 0, size.longestSide < tinyImageLimit {
            return .tinyImage
        }
        return nil
    }

    func isInsideProject(_ folders: [String], _ projectRoots: Set<String>) -> Bool {
        guard !projectRoots.isEmpty else { return false }
        var path = ""
        for folder in folders {
            path = path.isEmpty ? folder : path + "/" + folder
            if projectRoots.contains(path) { return true }
        }
        return false
    }

    func isAppData(_ folders: [String]) -> Bool {
        if folders.contains(where: { Self.cacheFolders.contains($0) }) { return true }
        // Android keeps each app's private files under Android/data/<package>/.
        // Shared app media (WhatsApp included) lives under Android/media/ and is not flagged.
        for index in folders.indices.dropLast() where folders[index] == "android" && folders[index + 1] == "data" {
            return true
        }
        return false
    }
}
