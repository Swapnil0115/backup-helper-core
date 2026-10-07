import Foundation

/// What kind of media a backup file holds.
public enum MediaKind: String, Codable, Hashable, Sendable {
    case photo
    case video
    /// Edit or metadata files that travel with a photo (.aae, .xmp).
    case sidecar
}

public struct PixelSize: Codable, Hashable, Sendable {
    public var width: Int
    public var height: Int

    public init(width: Int, height: Int) {
        self.width = width
        self.height = height
    }

    public var longestSide: Int { max(width, height) }

    /// Photos reports displayed (rotated) dimensions while ImageIO reports stored ones,
    /// so comparisons ignore orientation.
    public var orientationFreeCode: Int {
        min(width, height) * 100_000 + max(width, height)
    }
}

public enum DateSource: String, Codable, Hashable, Sendable {
    case embedded
    case fileName
    case folderName
    case fileModified

    public var label: String {
        switch self {
        case .embedded: return "Camera metadata"
        case .fileName: return "File name"
        case .folderName: return "Folder name"
        case .fileModified: return "File modified date"
        }
    }
}

public enum DatePrecision: String, Codable, Hashable, Sendable {
    case second
    case day
    case year
}

public enum Confidence: Int, Codable, Hashable, Comparable, Sendable {
    case low = 0
    case medium = 1
    case high = 2

    public static func < (lhs: Confidence, rhs: Confidence) -> Bool { lhs.rawValue < rhs.rawValue }

    public var label: String {
        switch self {
        case .low: return "Low"
        case .medium: return "Medium"
        case .high: return "High"
        }
    }
}

/// The best guess at when a photo was taken, and where that guess came from.
public struct InferredDate: Codable, Hashable, Sendable {
    public var date: Date
    public var source: DateSource
    public var precision: DatePrecision
    public var confidence: Confidence
    /// The source carried no time zone, so the Mac's current zone was assumed.
    public var isFloating: Bool

    public init(date: Date, source: DateSource, precision: DatePrecision, confidence: Confidence, isFloating: Bool) {
        self.date = date
        self.source = source
        self.precision = precision
        self.confidence = confidence
        self.isFloating = isFloating
    }
}

/// Facts read from a file's own header. Pixels are never decoded to get these.
public struct EmbeddedMetadata: Codable, Hashable, Sendable {
    public var captureDate: Date?
    public var captureDateIsFloating: Bool
    public var pixelSize: PixelSize?
    public var durationSeconds: Double?
    public var cameraMake: String?
    public var cameraModel: String?
    /// Apple's Live Photo pairing identifier, present in both halves of a Live Photo.
    public var contentIdentifier: String?

    public init(
        captureDate: Date? = nil,
        captureDateIsFloating: Bool = false,
        pixelSize: PixelSize? = nil,
        durationSeconds: Double? = nil,
        cameraMake: String? = nil,
        cameraModel: String? = nil,
        contentIdentifier: String? = nil
    ) {
        self.captureDate = captureDate
        self.captureDateIsFloating = captureDateIsFloating
        self.pixelSize = pixelSize
        self.durationSeconds = durationSeconds
        self.cameraMake = cameraMake
        self.cameraModel = cameraModel
        self.contentIdentifier = contentIdentifier
    }
}

/// One photo, video or sidecar found inside a backup folder.
public struct BackupFile: Codable, Hashable, Identifiable, Sendable {
    public var rootPath: String
    /// Path below the backup root, always "/"-separated.
    public var relativePath: String
    /// Absolute path; unique across every backup, so it doubles as the identifier.
    public var path: String
    public var kind: MediaKind
    public var byteSize: Int64
    public var modified: Date
    public var metadata: EmbeddedMetadata?
    public var inferredDate: InferredDate?
    public var junkReason: JunkReason?

    public init(
        rootPath: String,
        relativePath: String,
        kind: MediaKind,
        byteSize: Int64,
        modified: Date,
        metadata: EmbeddedMetadata? = nil,
        inferredDate: InferredDate? = nil,
        junkReason: JunkReason? = nil
    ) {
        self.rootPath = rootPath
        self.relativePath = relativePath
        self.path = rootPath.hasSuffix("/") ? rootPath + relativePath : rootPath + "/" + relativePath
        self.kind = kind
        self.byteSize = byteSize
        self.modified = modified
        self.metadata = metadata
        self.inferredDate = inferredDate
        self.junkReason = junkReason
    }

    public var id: String { path }
    public var url: URL { URL(fileURLWithPath: path) }

    public var fileName: String {
        relativePath.split(separator: "/").last.map(String.init) ?? relativePath
    }

    public var fileExtension: String { FileNames.splitExtension(fileName).ext.lowercased() }

    /// Folder below the backup root; "" for files directly in the root.
    public var folderPath: String {
        guard let slash = relativePath.lastIndex(of: "/") else { return "" }
        return String(relativePath[..<slash])
    }

    public var isSupportedByPhotos: Bool { !MediaTypes.unsupportedByPhotos.contains(fileExtension) }
}

/// Metadata-only snapshot of one item in the Photos library.
public struct LibraryAsset: Codable, Hashable, Identifiable, Sendable {
    /// PhotoKit's local identifier.
    public var id: String
    public var kind: MediaKind
    public var originalFileName: String?
    /// Original name of the video half when the asset is a Live Photo.
    public var pairedVideoFileName: String?
    public var creationDate: Date?
    public var pixelSize: PixelSize?
    public var durationSeconds: Double?

    public init(
        id: String,
        kind: MediaKind,
        originalFileName: String? = nil,
        pairedVideoFileName: String? = nil,
        creationDate: Date? = nil,
        pixelSize: PixelSize? = nil,
        durationSeconds: Double? = nil
    ) {
        self.id = id
        self.kind = kind
        self.originalFileName = originalFileName
        self.pairedVideoFileName = pairedVideoFileName
        self.creationDate = creationDate
        self.pixelSize = pixelSize
        self.durationSeconds = durationSeconds
    }
}

public enum CoverageState: String, Codable, Hashable, Sendable, CaseIterable {
    case inPhotos
    case probablyInPhotos
    case notInPhotos
    case junk
    case sidecar
    /// Photos access was not granted, so no comparison was made.
    case unchecked

    public var label: String {
        switch self {
        case .inPhotos: return "In Photos"
        case .probablyInPhotos: return "Probably in Photos"
        case .notInPhotos: return "Not in Photos"
        case .junk: return "Probably junk"
        case .sidecar: return "Edit or sidecar file"
        case .unchecked: return "Not compared yet"
        }
    }
}

public enum MatchEvidence: String, Codable, Hashable, Sendable {
    case nameDimensionsDate
    case nameDuration
    case nameDimensions
    case nameDateResized
    case livePhotoVideo
    case dimensionsDate
    case dimensionsShiftedDate
    case dimensionsDuration

    public var label: String {
        switch self {
        case .nameDimensionsDate: return "Same file name, size and capture time"
        case .nameDuration: return "Same file name and video length"
        case .nameDimensions: return "Same file name and size; no capture time to compare"
        case .nameDateResized: return "Same file name and capture time, different size (cropped or edited in Photos?)"
        case .livePhotoVideo: return "Video half of a Live Photo in your library"
        case .dimensionsDate: return "Same size and capture time, different file name"
        case .dimensionsShiftedDate: return "Same size; capture time differs by a time-zone offset"
        case .dimensionsDuration: return "Same size and video length"
        }
    }
}

public struct MatchResult: Codable, Hashable, Sendable {
    public var state: CoverageState
    public var assetID: String?
    public var evidence: MatchEvidence?

    public init(state: CoverageState, assetID: String? = nil, evidence: MatchEvidence? = nil) {
        self.state = state
        self.assetID = assetID
        self.evidence = evidence
    }
}

public enum FileNames {
    public static func splitExtension(_ name: String) -> (stem: String, ext: String) {
        guard let dot = name.lastIndex(of: "."), dot != name.startIndex else { return (name, "") }
        return (String(name[..<dot]), String(name[name.index(after: dot)...]))
    }

    /// Lower-cased name without extension or the " (1)" that copy tools add on collisions.
    public static func normalizedStem(_ name: String) -> String {
        var stem = splitExtension(name).stem.lowercased()
        if stem.hasSuffix(")"), let open = stem.range(of: " (", options: .backwards) {
            let inner = stem[open.upperBound..<stem.index(before: stem.endIndex)]
            if !inner.isEmpty, inner.allSatisfy(\.isNumber) {
                stem = String(stem[..<open.lowerBound])
            }
        }
        return stem
    }
}
