@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsReferenceRangeSegmentViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Labs.newReferenceRangeSegment("code-667", name: "name-414")
        let view = Labs.toReferenceRangeSegmentView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Labs.toReferenceRangeSegmentViews([item, item]).count == 2)
    }
}
