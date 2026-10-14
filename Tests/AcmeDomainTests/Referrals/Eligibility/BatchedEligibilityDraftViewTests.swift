@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsBatchedEligibilityDraftViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Referrals.newBatchedEligibilityDraft("code-949", title: "title-273")
        let view = Referrals.toBatchedEligibilityDraftView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Referrals.toBatchedEligibilityDraftViews([item, item]).count == 2)
    }
}
