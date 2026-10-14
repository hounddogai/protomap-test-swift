@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingPrimaryAcuityPlanTargetViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Staffing.newPrimaryAcuityPlanTarget("code-593", title: "title-363")
        let view = Staffing.toPrimaryAcuityPlanTargetView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Staffing.toPrimaryAcuityPlanTargetViews([item, item]).count == 2)
    }
}
