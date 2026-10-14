@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementGoalTierViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = CareManagement.newGoalTier("code-148", label: "label-919")
        let view = CareManagement.toGoalTierView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(CareManagement.toGoalTierViews([item, item]).count == 2)
    }
}
