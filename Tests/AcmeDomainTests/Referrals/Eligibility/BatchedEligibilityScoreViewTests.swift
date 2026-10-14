@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsBatchedEligibilityScoreViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Referrals.newBatchedEligibilityScore("code-401", title: "title-206")
        let view = Referrals.toBatchedEligibilityScoreView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Referrals.toBatchedEligibilityScoreViews([item, item]).count == 2)
    }
}
