@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsClosureMetricViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Referrals.newClosureMetric("code-285", title: "title-883")
        let view = Referrals.toClosureMetricView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Referrals.toClosureMetricViews([item, item]).count == 2)
    }
}
