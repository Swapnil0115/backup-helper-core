import XCTest
@testable import BackupHelperCore

final class ModelsTests: XCTestCase {
    func testNormalizedStemDropsExtensionCaseAndCopySuffix() {
        XCTAssertEqual(FileNames.normalizedStem("IMG_1234.HEIC"), "img_1234")
        XCTAssertEqual(FileNames.normalizedStem("IMG_1234 (2).jpg"), "img_1234")
        XCTAssertEqual(FileNames.normalizedStem("Trip (Goa).jpg"), "trip (goa)")
        XCTAssertEqual(FileNames.normalizedStem(".hidden"), ".hidden")
    }

    func testOrientationFreeSize() {
        XCTAssertEqual(PixelSize(width: 4032, height: 3024).orientationFreeCode,
                       PixelSize(width: 3024, height: 4032).orientationFreeCode)
        XCTAssertNotEqual(PixelSize(width: 4032, height: 3024).orientationFreeCode,
                          PixelSize(width: 4000, height: 3000).orientationFreeCode)
    }

    func testMediaKinds() {
        XCTAssertEqual(MediaTypes.kind(forExtension: "HEIC"), .photo)
        XCTAssertEqual(MediaTypes.kind(forExtension: "mov"), .video)
        XCTAssertEqual(MediaTypes.kind(forExtension: "aae"), .sidecar)
        XCTAssertNil(MediaTypes.kind(forExtension: "ts"))
    }

    func testBackupFilePaths() {
        let file = BackupFile(rootPath: "/Volumes/Backup/", relativePath: "Trip/Day 1/IMG_1.webm",
                              kind: .video, byteSize: 1, modified: Date())
        XCTAssertEqual(file.path, "/Volumes/Backup/Trip/Day 1/IMG_1.webm")
        XCTAssertEqual(file.folderPath, "Trip/Day 1")
        XCTAssertEqual(file.fileName, "IMG_1.webm")
        XCTAssertFalse(file.isSupportedByPhotos)
    }
}
