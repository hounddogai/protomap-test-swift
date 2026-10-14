@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementPendingGoalPreferenceViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = CareManagement.newPendingGoalPreference("code-936", name: "name-108")
        let view = CareManagement.toPendingGoalPreferenceView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(CareManagement.toPendingGoalPreferenceViews([item, item]).count == 2)
    }
}
