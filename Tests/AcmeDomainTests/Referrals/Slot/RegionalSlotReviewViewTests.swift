@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsRegionalSlotReviewViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Referrals.newRegionalSlotReview("code-921", title: "title-782")
        let view = Referrals.toRegionalSlotReviewView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Referrals.toRegionalSlotReviewViews([item, item]).count == 2)
    }
}
