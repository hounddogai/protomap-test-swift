@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingTieredAcuityPlanMilestoneViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Staffing.newTieredAcuityPlanMilestone("code-452", name: "name-213")
        let view = Staffing.toTieredAcuityPlanMilestoneView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Staffing.toTieredAcuityPlanMilestoneViews([item, item]).count == 2)
    }
}
