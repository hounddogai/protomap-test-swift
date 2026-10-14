@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementGoalPlanViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = CareManagement.newGoalPlan("code-84", name: "name-761")
        let view = CareManagement.toGoalPlanView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(CareManagement.toGoalPlanViews([item, item]).count == 2)
    }
}
