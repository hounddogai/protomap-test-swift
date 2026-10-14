@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsScheduledEligibilityDraftViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Referrals.newScheduledEligibilityDraft("code-412", name: "name-403")
        let view = Referrals.toScheduledEligibilityDraftView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Referrals.toScheduledEligibilityDraftViews([item, item]).count == 2)
    }
}
