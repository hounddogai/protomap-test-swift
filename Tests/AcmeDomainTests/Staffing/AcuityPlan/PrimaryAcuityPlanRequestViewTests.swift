@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingPrimaryAcuityPlanRequestViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Staffing.newPrimaryAcuityPlanRequest("code-136", name: "name-400")
        let view = Staffing.toPrimaryAcuityPlanRequestView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Staffing.toPrimaryAcuityPlanRequestViews([item, item]).count == 2)
    }
}
