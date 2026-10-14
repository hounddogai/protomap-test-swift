@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementIsolationSegmentViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = BedManagement.newIsolationSegment("code-105", title: "title-424")
        let view = BedManagement.toIsolationSegmentView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(BedManagement.toIsolationSegmentViews([item, item]).count == 2)
    }
}
