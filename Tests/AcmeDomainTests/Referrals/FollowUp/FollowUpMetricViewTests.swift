@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsFollowUpMetricViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Referrals.newFollowUpMetric("code-332", label: "label-555")
        let view = Referrals.toFollowUpMetricView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Referrals.toFollowUpMetricViews([item, item]).count == 2)
    }
}
