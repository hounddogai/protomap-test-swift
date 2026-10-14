@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementLegacyDischargePlanAdjustmentViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = BedManagement.newLegacyDischargePlanAdjustment("code-414", label: "label-787")
        let view = BedManagement.toLegacyDischargePlanAdjustmentView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(BedManagement.toLegacyDischargePlanAdjustmentViews([item, item]).count == 2)
    }
}
