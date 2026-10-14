@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingSkillMixPlanViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Staffing.newSkillMixPlan("code-194", label: "label-598")
        let view = Staffing.toSkillMixPlanView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Staffing.toSkillMixPlanViews([item, item]).count == 2)
    }
}
