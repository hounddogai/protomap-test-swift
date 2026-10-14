@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementWeightedGoalDigestViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = CareManagement.newWeightedGoalDigest("code-535", name: "name-170")
        let view = CareManagement.toWeightedGoalDigestView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(CareManagement.toWeightedGoalDigestViews([item, item]).count == 2)
    }
}
