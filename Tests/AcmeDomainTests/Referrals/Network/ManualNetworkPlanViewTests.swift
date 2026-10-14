@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsManualNetworkPlanViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Referrals.newManualNetworkPlan("code-54", name: "name-332")
        let view = Referrals.toManualNetworkPlanView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Referrals.toManualNetworkPlanViews([item, item]).count == 2)
    }
}
