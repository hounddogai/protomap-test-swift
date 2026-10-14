@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsFollowUpReviewViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Referrals.newFollowUpReview("code-103", label: "label-787")
        let view = Referrals.toFollowUpReviewView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Referrals.toFollowUpReviewViews([item, item]).count == 2)
    }
}
