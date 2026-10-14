@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementLegacyIsolationSegmentViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = BedManagement.newLegacyIsolationSegment("code-374", title: "title-576")
        let view = BedManagement.toLegacyIsolationSegmentView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(BedManagement.toLegacyIsolationSegmentViews([item, item]).count == 2)
    }
}
