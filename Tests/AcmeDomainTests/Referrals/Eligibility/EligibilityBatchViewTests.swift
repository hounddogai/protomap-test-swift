@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsEligibilityBatchViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Referrals.newEligibilityBatch("code-947", title: "title-639")
        let view = Referrals.toEligibilityBatchView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Referrals.toEligibilityBatchViews([item, item]).count == 2)
    }
}
