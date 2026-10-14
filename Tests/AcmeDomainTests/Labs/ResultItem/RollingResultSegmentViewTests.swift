@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsRollingResultSegmentViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Labs.newRollingResultSegment("code-635", label: "label-746")
        let view = Labs.toRollingResultSegmentView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Labs.toRollingResultSegmentViews([item, item]).count == 2)
    }
}
