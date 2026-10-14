@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsPendingResultSegmentViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Labs.newPendingResultSegment("code-541", title: "title-352")
        let view = Labs.toPendingResultSegmentView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Labs.toPendingResultSegmentViews([item, item]).count == 2)
    }
}
