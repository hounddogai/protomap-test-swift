@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingAcuityPlanGroupViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Staffing.newAcuityPlanGroup("code-877", label: "label-164")
        let view = Staffing.toAcuityPlanGroupView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Staffing.toAcuityPlanGroupViews([item, item]).count == 2)
    }
}
