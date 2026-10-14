@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementFallbackGoalClaimViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = CareManagement.newFallbackGoalClaim("code-618", title: "title-78")
        let view = CareManagement.toFallbackGoalClaimView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(CareManagement.toFallbackGoalClaimViews([item, item]).count == 2)
    }
}
