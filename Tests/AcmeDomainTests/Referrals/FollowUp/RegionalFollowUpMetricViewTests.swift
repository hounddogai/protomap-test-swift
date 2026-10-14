@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsRegionalFollowUpMetricViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Referrals.newRegionalFollowUpMetric("code-343", label: "label-262")
        let view = Referrals.toRegionalFollowUpMetricView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Referrals.toRegionalFollowUpMetricViews([item, item]).count == 2)
    }
}
