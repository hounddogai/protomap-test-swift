@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingCareProtocolSegmentViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Imaging.newCareProtocolSegment("code-138", name: "name-816")
        let view = Imaging.toCareProtocolSegmentView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Imaging.toCareProtocolSegmentViews([item, item]).count == 2)
    }
}
