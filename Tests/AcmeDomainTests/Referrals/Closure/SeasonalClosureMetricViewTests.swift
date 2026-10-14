@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsSeasonalClosureMetricViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Referrals.newSeasonalClosureMetric("code-309", name: "name-802")
        let view = Referrals.toSeasonalClosureMetricView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Referrals.toSeasonalClosureMetricViews([item, item]).count == 2)
    }
}
