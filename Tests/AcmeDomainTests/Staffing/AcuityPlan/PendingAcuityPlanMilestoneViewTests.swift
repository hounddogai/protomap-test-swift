@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingPendingAcuityPlanMilestoneViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Staffing.newPendingAcuityPlanMilestone("code-211", label: "label-559")
        let view = Staffing.toPendingAcuityPlanMilestoneView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Staffing.toPendingAcuityPlanMilestoneViews([item, item]).count == 2)
    }
}
