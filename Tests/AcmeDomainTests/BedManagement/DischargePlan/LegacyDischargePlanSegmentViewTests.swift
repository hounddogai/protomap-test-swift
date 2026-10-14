@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementLegacyDischargePlanSegmentViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = BedManagement.newLegacyDischargePlanSegment("code-844", title: "title-94")
        let view = BedManagement.toLegacyDischargePlanSegmentView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(BedManagement.toLegacyDischargePlanSegmentViews([item, item]).count == 2)
    }
}
