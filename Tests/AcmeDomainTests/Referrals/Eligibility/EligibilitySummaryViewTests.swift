@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsEligibilitySummaryViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Referrals.newEligibilitySummary("code-269", title: "title-555")
        let view = Referrals.toEligibilitySummaryView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Referrals.toEligibilitySummaryViews([item, item]).count == 2)
    }
}
