@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsSeasonalNetworkCycleViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Referrals.newSeasonalNetworkCycle("code-933", name: "name-643")
        let view = Referrals.toSeasonalNetworkCycleView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Referrals.toSeasonalNetworkCycleViews([item, item]).count == 2)
    }
}
