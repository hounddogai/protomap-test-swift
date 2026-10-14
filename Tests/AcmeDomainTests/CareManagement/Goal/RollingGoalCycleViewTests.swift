@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementRollingGoalCycleViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = CareManagement.newRollingGoalCycle("code-329", title: "title-472")
        let view = CareManagement.toRollingGoalCycleView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(CareManagement.toRollingGoalCycleViews([item, item]).count == 2)
    }
}
