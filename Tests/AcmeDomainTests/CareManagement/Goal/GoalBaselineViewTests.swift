@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementGoalBaselineViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = CareManagement.newGoalBaseline("code-28", name: "name-857")
        let view = CareManagement.toGoalBaselineView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(CareManagement.toGoalBaselineViews([item, item]).count == 2)
    }
}
