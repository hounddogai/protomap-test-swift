@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementPendingGoalScheduleViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = CareManagement.newPendingGoalSchedule("code-822", name: "name-976")
        let view = CareManagement.toPendingGoalScheduleView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(CareManagement.toPendingGoalScheduleViews([item, item]).count == 2)
    }
}
