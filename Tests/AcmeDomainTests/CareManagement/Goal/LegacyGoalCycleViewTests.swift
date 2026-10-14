@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementLegacyGoalCycleViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = CareManagement.newLegacyGoalCycle("code-738", title: "title-456")
        let view = CareManagement.toLegacyGoalCycleView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(CareManagement.toLegacyGoalCycleViews([item, item]).count == 2)
    }
}
