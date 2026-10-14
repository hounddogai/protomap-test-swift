@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementGoalTargetViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = CareManagement.newGoalTarget("code-523", name: "name-851")
        let view = CareManagement.toGoalTargetView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(CareManagement.toGoalTargetViews([item, item]).count == 2)
    }
}
