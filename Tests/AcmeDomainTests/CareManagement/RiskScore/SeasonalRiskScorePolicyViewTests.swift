@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementSeasonalRiskScorePolicyViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = CareManagement.newSeasonalRiskScorePolicy("code-425", name: "name-501")
        let view = CareManagement.toSeasonalRiskScorePolicyView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(CareManagement.toSeasonalRiskScorePolicyViews([item, item]).count == 2)
    }
}
