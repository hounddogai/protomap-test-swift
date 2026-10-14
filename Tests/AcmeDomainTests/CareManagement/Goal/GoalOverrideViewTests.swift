@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementGoalOverrideViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = CareManagement.newGoalOverride("code-906", name: "name-982")
        let view = CareManagement.toGoalOverrideView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(CareManagement.toGoalOverrideViews([item, item]).count == 2)
    }
}
