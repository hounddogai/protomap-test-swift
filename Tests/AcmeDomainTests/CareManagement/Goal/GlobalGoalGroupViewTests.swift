@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementGlobalGoalGroupViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = CareManagement.newGlobalGoalGroup("code-482", title: "title-926")
        let view = CareManagement.toGlobalGoalGroupView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(CareManagement.toGlobalGoalGroupViews([item, item]).count == 2)
    }
}
