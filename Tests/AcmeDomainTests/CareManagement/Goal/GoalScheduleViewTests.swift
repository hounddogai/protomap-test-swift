@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementGoalScheduleViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = CareManagement.newGoalSchedule("code-338", name: "name-298")
        let view = CareManagement.toGoalScheduleView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(CareManagement.toGoalScheduleViews([item, item]).count == 2)
    }
}
