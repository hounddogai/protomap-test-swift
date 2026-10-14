@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsClosureReviewViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Referrals.newClosureReview("code-943", name: "name-445")
        let view = Referrals.toClosureReviewView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Referrals.toClosureReviewViews([item, item]).count == 2)
    }
}
