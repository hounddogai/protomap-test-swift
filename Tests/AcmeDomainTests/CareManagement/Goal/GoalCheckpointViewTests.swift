@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementGoalCheckpointViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = CareManagement.newGoalCheckpoint("code-262", title: "title-314")
        let view = CareManagement.toGoalCheckpointView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(CareManagement.toGoalCheckpointViews([item, item]).count == 2)
    }
}
