@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementStrictGoalGroupViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = CareManagement.newStrictGoalGroup("code-750", name: "name-44")
        let view = CareManagement.toStrictGoalGroupView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(CareManagement.toStrictGoalGroupViews([item, item]).count == 2)
    }
}
