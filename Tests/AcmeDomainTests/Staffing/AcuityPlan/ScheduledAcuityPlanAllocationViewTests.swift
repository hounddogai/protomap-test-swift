@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingScheduledAcuityPlanAllocationViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Staffing.newScheduledAcuityPlanAllocation("code-975", label: "label-735")
        let view = Staffing.toScheduledAcuityPlanAllocationView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Staffing.toScheduledAcuityPlanAllocationViews([item, item]).count == 2)
    }
}
