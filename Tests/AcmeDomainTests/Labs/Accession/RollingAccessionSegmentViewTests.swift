@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsRollingAccessionSegmentViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Labs.newRollingAccessionSegment("code-617", label: "label-608")
        let view = Labs.toRollingAccessionSegmentView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Labs.toRollingAccessionSegmentViews([item, item]).count == 2)
    }
}
