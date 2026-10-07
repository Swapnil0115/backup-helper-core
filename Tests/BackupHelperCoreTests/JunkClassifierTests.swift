import XCTest
@testable import BackupHelperCore

final class JunkClassifierTests: XCTestCase {
    let classifier = JunkClassifier()

    func reason(_ path: String, size: PixelSize? = nil, projects: Set<String> = []) -> JunkReason? {
        classifier.classify(relativePath: path, kind: .photo, metadata: size.map { EmbeddedMetadata(pixelSize: $0) }, projectRoots: projects)
    }

    func testCameraPhotoIsKept() {
        XCTAssertNil(reason("PhoneBackup/DCIM/Camera/IMG_20230512_143022.jpg"))
        XCTAssertNil(reason("Android/media/com.whatsapp/WhatsApp/Media/WhatsApp Images/IMG-20230512-WA0012.jpg"))
    }

    func testAndroidThumbnails() {
        XCTAssertEqual(reason("PhoneBackup/Pictures/.thumbnails/1234.jpg"), .thumbnailCache)
    }

    func testAppPrivateData() {
        XCTAssertEqual(reason("PhoneBackup/Android/data/com.example.shop/cache/images/a.jpg"), .appData)
        XCTAssertEqual(reason("PhoneBackup/Android/data/com.example.player/files/x.jpg"), .appData)
    }

    func testWhatsAppLinkPreviewsAndStickers() {
        XCTAssertEqual(reason("WhatsApp/Media/.Links/abc.jpg"), .linkPreview)
        XCTAssertEqual(reason("WhatsApp/Media/WhatsApp Stickers/s.webp"), .sticker)
    }

    func testCodeProjects() {
        XCTAssertEqual(reason("Projects/Shop/env/Lib/site-packages/pkg/logo.png"), .codeProject)
        XCTAssertEqual(reason("Projects/Shop/static/img/logo.png", projects: ["projects/shop"]), .codeProject)
        XCTAssertEqual(reason("App/res/drawable-hdpi/icon.png"), .codeProject)
    }

    func testTrashAndSystemFiles() {
        XCTAssertEqual(reason("DCIM/Camera/.trashed-1690000000-IMG_1.jpg"), .deletedOnDevice)
        XCTAssertEqual(reason("DCIM/Camera/._IMG_1.jpg"), .systemFile)
    }

    func testTinyImages() {
        XCTAssertEqual(reason("Downloads/icon.png", size: PixelSize(width: 64, height: 64)), .tinyImage)
        XCTAssertNil(reason("Downloads/photo.png", size: PixelSize(width: 1080, height: 1920)))
    }
}
