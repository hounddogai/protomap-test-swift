@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsPendingEligibilityPreferenceViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Referrals.newPendingEligibilityPreference("code-440", title: "title-453")
        let view = Referrals.toPendingEligibilityPreferenceView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Referrals.toPendingEligibilityPreferenceViews([item, item]).count == 2)
    }
}
