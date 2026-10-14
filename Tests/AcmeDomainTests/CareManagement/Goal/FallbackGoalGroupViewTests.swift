@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementFallbackGoalGroupViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = CareManagement.newFallbackGoalGroup("code-336", title: "title-753")
        let view = CareManagement.toFallbackGoalGroupView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(CareManagement.toFallbackGoalGroupViews([item, item]).count == 2)
    }
}
