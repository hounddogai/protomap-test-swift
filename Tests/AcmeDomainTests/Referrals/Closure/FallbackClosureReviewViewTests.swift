@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsFallbackClosureReviewViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Referrals.newFallbackClosureReview("code-369", label: "label-554")
        let view = Referrals.toFallbackClosureReviewView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Referrals.toFallbackClosureReviewViews([item, item]).count == 2)
    }
}
