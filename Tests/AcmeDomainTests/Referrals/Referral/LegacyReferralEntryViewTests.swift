@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsLegacyReferralEntryViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Referrals.newLegacyReferralEntry("code-300", title: "title-200")
        let view = Referrals.toLegacyReferralEntryView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Referrals.toLegacyReferralEntryViews([item, item]).count == 2)
    }
}
