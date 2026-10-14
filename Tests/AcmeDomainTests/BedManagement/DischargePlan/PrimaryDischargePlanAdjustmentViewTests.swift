@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementPrimaryDischargePlanAdjustmentViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = BedManagement.newPrimaryDischargePlanAdjustment("code-205", title: "title-474")
        let view = BedManagement.toPrimaryDischargePlanAdjustmentView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(BedManagement.toPrimaryDischargePlanAdjustmentViews([item, item]).count == 2)
    }
}
