@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsPanelSegmentViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Labs.newPanelSegment("code-632", label: "label-144")
        let view = Labs.toPanelSegmentView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Labs.toPanelSegmentViews([item, item]).count == 2)
    }
}
