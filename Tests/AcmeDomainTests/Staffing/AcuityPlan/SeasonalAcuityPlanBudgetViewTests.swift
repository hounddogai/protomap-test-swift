@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingSeasonalAcuityPlanBudgetViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Staffing.newSeasonalAcuityPlanBudget("code-538", name: "name-531")
        let view = Staffing.toSeasonalAcuityPlanBudgetView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Staffing.toSeasonalAcuityPlanBudgetViews([item, item]).count == 2)
    }
}
