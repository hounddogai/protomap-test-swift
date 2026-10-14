@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingPrimaryAcuityPlanQuotaViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Staffing.newPrimaryAcuityPlanQuota("code-820", label: "label-727")
        let view = Staffing.toPrimaryAcuityPlanQuotaView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Staffing.toPrimaryAcuityPlanQuotaViews([item, item]).count == 2)
    }
}
