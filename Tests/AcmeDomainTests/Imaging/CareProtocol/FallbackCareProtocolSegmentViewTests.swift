@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingFallbackCareProtocolSegmentViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Imaging.newFallbackCareProtocolSegment("code-716", title: "title-137")
        let view = Imaging.toFallbackCareProtocolSegmentView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Imaging.toFallbackCareProtocolSegmentViews([item, item]).count == 2)
    }
}
