@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsTieredFollowUpMetricViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Referrals.newTieredFollowUpMetric("code-886", label: "label-993")
        let view = Referrals.toTieredFollowUpMetricView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Referrals.toTieredFollowUpMetricViews([item, item]).count == 2)
    }
}
