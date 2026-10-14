@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingLenientAcuityPlanAllocationViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Staffing.newLenientAcuityPlanAllocation("code-918", title: "title-632")
        let view = Staffing.toLenientAcuityPlanAllocationView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Staffing.toLenientAcuityPlanAllocationViews([item, item]).count == 2)
    }
}
