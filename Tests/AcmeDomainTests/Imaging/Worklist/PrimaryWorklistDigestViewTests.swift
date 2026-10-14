@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingPrimaryWorklistDigestViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Imaging.newPrimaryWorklistDigest("code-811", title: "title-289")
        let view = Imaging.toPrimaryWorklistDigestView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Imaging.toPrimaryWorklistDigestViews([item, item]).count == 2)
    }
}
