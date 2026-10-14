@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingWorklistDigestViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Imaging.newWorklistDigest("code-550", title: "title-82")
        let view = Imaging.toWorklistDigestView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Imaging.toWorklistDigestViews([item, item]).count == 2)
    }
}
