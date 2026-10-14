@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingTieredAcuityPlanOverrideViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Staffing.newTieredAcuityPlanOverride("code-144", name: "name-307")
        let view = Staffing.toTieredAcuityPlanOverrideView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Staffing.toTieredAcuityPlanOverrideViews([item, item]).count == 2)
    }
}
