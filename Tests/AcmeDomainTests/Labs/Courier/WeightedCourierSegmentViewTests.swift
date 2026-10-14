@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsWeightedCourierSegmentViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Labs.newWeightedCourierSegment("code-212", label: "label-800")
        let view = Labs.toWeightedCourierSegmentView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Labs.toWeightedCourierSegmentViews([item, item]).count == 2)
    }
}
