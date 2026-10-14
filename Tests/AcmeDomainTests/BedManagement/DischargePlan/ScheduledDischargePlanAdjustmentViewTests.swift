@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementScheduledDischargePlanAdjustmentViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = BedManagement.newScheduledDischargePlanAdjustment("code-473", title: "title-957")
        let view = BedManagement.toScheduledDischargePlanAdjustmentView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(BedManagement.toScheduledDischargePlanAdjustmentViews([item, item]).count == 2)
    }
}
