@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementScheduledIsolationSegmentViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = BedManagement.newScheduledIsolationSegment("code-22", name: "name-78")
        let view = BedManagement.toScheduledIsolationSegmentView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(BedManagement.toScheduledIsolationSegmentViews([item, item]).count == 2)
    }
}
