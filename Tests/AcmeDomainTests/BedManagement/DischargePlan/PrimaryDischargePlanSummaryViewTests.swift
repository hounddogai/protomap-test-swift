@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementPrimaryDischargePlanSummaryViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = BedManagement.newPrimaryDischargePlanSummary("code-379", title: "title-784")
        let view = BedManagement.toPrimaryDischargePlanSummaryView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(BedManagement.toPrimaryDischargePlanSummaryViews([item, item]).count == 2)
    }
}
