@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementCappedGoalGroupViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = CareManagement.newCappedGoalGroup("code-328", label: "label-723")
        let view = CareManagement.toCappedGoalGroupView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(CareManagement.toCappedGoalGroupViews([item, item]).count == 2)
    }
}
