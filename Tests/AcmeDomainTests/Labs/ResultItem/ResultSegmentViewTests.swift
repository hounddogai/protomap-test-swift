@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsResultSegmentViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Labs.newResultSegment("code-457", label: "label-798")
        let view = Labs.toResultSegmentView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Labs.toResultSegmentViews([item, item]).count == 2)
    }
}
