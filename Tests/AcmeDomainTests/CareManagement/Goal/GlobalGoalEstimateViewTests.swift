@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementGlobalGoalEstimateViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = CareManagement.newGlobalGoalEstimate("code-107", name: "name-412")
        let view = CareManagement.toGlobalGoalEstimateView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(CareManagement.toGlobalGoalEstimateViews([item, item]).count == 2)
    }
}
