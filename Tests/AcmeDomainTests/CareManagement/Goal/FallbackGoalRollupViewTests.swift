@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementFallbackGoalRollupViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = CareManagement.newFallbackGoalRollup("code-892", name: "name-576")
        let view = CareManagement.toFallbackGoalRollupView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(CareManagement.toFallbackGoalRollupViews([item, item]).count == 2)
    }
}
