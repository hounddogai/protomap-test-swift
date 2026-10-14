@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingAcuityPlanClaimViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Staffing.newAcuityPlanClaim("code-641", name: "name-180")
        let view = Staffing.toAcuityPlanClaimView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Staffing.toAcuityPlanClaimViews([item, item]).count == 2)
    }
}
