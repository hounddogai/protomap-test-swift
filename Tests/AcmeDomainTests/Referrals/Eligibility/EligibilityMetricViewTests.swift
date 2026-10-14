@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsEligibilityMetricViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Referrals.newEligibilityMetric("code-964", title: "title-423")
        let view = Referrals.toEligibilityMetricView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Referrals.toEligibilityMetricViews([item, item]).count == 2)
    }
}
