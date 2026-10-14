@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsSpecimenSegmentViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Labs.newSpecimenSegment("code-860", name: "name-318")
        let view = Labs.toSpecimenSegmentView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Labs.toSpecimenSegmentViews([item, item]).count == 2)
    }
}
