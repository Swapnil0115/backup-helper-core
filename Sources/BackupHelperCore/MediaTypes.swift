import Foundation

public enum MediaTypes {
    public static let photoExtensions: Set<String> = [
        "jpg", "jpeg", "jpe", "jfif", "heic", "heif", "png", "gif", "webp", "avif", "tif", "tiff", "bmp", "psd",
        "dng", "cr2", "cr3", "nef", "arw", "orf", "rw2", "raf", "srw", "pef",
    ]

    // "ts" is left out on purpose: in real backups it is almost always TypeScript, not video.
    public static let videoExtensions: Set<String> = [
        "mov", "mp4", "m4v", "3gp", "3g2", "avi", "mts", "m2ts", "mkv", "webm", "mpg", "mpeg",
    ]

    public static let sidecarExtensions: Set<String> = ["aae", "xmp", "thm"]

    /// Formats Photos for macOS refuses to import.
    public static let unsupportedByPhotos: Set<String> = ["webm", "mkv", "wmv", "flv"]

    public static func kind(forExtension ext: String) -> MediaKind? {
        let lower = ext.lowercased()
        if photoExtensions.contains(lower) { return .photo }
        if videoExtensions.contains(lower) { return .video }
        if sidecarExtensions.contains(lower) { return .sidecar }
        return nil
    }
}
