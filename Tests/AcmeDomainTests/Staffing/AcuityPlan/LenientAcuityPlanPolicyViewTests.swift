@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingLenientAcuityPlanPolicyViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Staffing.newLenientAcuityPlanPolicy("code-345", label: "label-930")
        let view = Staffing.toLenientAcuityPlanPolicyView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Staffing.toLenientAcuityPlanPolicyViews([item, item]).count == 2)
    }
}
