@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsGlobalReferenceRangeSegmentViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Labs.newGlobalReferenceRangeSegment("code-324", label: "label-439")
        let view = Labs.toGlobalReferenceRangeSegmentView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Labs.toGlobalReferenceRangeSegmentViews([item, item]).count == 2)
    }
}
