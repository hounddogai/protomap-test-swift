@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsCappedResultSegmentViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Labs.newCappedResultSegment("code-493", label: "label-917")
        let view = Labs.toCappedResultSegmentView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Labs.toCappedResultSegmentViews([item, item]).count == 2)
    }
}
