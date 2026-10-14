@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsWeightedFollowUpMetricViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Referrals.newWeightedFollowUpMetric("code-679", title: "title-121")
        let view = Referrals.toWeightedFollowUpMetricView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Referrals.toWeightedFollowUpMetricViews([item, item]).count == 2)
    }
}
