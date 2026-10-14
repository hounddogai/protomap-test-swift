@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingPrioritySegmentViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Imaging.newPrioritySegment("code-539", name: "name-770")
        let view = Imaging.toPrioritySegmentView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Imaging.toPrioritySegmentViews([item, item]).count == 2)
    }
}
