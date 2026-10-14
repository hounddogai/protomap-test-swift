@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementScheduledGoalPolicyViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = CareManagement.newScheduledGoalPolicy("code-255", title: "title-533")
        let view = CareManagement.toScheduledGoalPolicyView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(CareManagement.toScheduledGoalPolicyViews([item, item]).count == 2)
    }
}
