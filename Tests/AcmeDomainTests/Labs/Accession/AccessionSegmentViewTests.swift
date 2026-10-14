@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsAccessionSegmentViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Labs.newAccessionSegment("code-814", label: "label-15")
        let view = Labs.toAccessionSegmentView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Labs.toAccessionSegmentViews([item, item]).count == 2)
    }
}
