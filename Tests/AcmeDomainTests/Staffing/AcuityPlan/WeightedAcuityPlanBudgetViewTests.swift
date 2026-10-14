@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingWeightedAcuityPlanBudgetViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Staffing.newWeightedAcuityPlanBudget("code-490", label: "label-276")
        let view = Staffing.toWeightedAcuityPlanBudgetView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Staffing.toWeightedAcuityPlanBudgetViews([item, item]).count == 2)
    }
}
