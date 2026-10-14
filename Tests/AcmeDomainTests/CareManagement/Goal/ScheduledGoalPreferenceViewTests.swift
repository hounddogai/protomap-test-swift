@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementScheduledGoalPreferenceViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = CareManagement.newScheduledGoalPreference("code-17", name: "name-227")
        let view = CareManagement.toScheduledGoalPreferenceView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(CareManagement.toScheduledGoalPreferenceViews([item, item]).count == 2)
    }
}
