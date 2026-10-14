@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingLegacyAcuityPlanPolicyViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Staffing.newLegacyAcuityPlanPolicy("code-231", label: "label-557")
        let view = Staffing.toLegacyAcuityPlanPolicyView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Staffing.toLegacyAcuityPlanPolicyViews([item, item]).count == 2)
    }
}
