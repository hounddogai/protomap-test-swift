@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingStudyManifestViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Imaging.newStudyManifest("code-420", name: "name-24")
        let view = Imaging.toStudyManifestView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Imaging.toStudyManifestViews([item, item]).count == 2)
    }
}
