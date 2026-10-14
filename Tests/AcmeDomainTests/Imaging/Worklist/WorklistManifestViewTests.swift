@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingWorklistManifestViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Imaging.newWorklistManifest("code-612", title: "title-730")
        let view = Imaging.toWorklistManifestView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Imaging.toWorklistManifestViews([item, item]).count == 2)
    }
}
