@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingLenientCareProtocolSegmentViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Imaging.newLenientCareProtocolSegment("code-231", title: "title-100")
        let view = Imaging.toLenientCareProtocolSegmentView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Imaging.toLenientCareProtocolSegmentViews([item, item]).count == 2)
    }
}
