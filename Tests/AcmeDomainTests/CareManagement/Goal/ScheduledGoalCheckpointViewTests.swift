@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementScheduledGoalCheckpointViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = CareManagement.newScheduledGoalCheckpoint("code-284", title: "title-359")
        let view = CareManagement.toScheduledGoalCheckpointView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(CareManagement.toScheduledGoalCheckpointViews([item, item]).count == 2)
    }
}
