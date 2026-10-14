@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingSeasonalSkillMixPlanViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Staffing.newSeasonalSkillMixPlan("code-319", label: "label-564")
        let view = Staffing.toSeasonalSkillMixPlanView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Staffing.toSeasonalSkillMixPlanViews([item, item]).count == 2)
    }
}
