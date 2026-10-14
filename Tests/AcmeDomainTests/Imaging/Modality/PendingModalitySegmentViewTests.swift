@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingPendingModalitySegmentViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Imaging.newPendingModalitySegment("code-219", title: "title-576")
        let view = Imaging.toPendingModalitySegmentView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Imaging.toPendingModalitySegmentViews([item, item]).count == 2)
    }
}
