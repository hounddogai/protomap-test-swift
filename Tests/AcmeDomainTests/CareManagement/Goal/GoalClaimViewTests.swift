@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementGoalClaimViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = CareManagement.newGoalClaim("code-513", name: "name-184")
        let view = CareManagement.toGoalClaimView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(CareManagement.toGoalClaimViews([item, item]).count == 2)
    }
}
