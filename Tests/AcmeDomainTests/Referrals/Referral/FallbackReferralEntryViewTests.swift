@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsFallbackReferralEntryViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Referrals.newFallbackReferralEntry("code-294", title: "title-658")
        let view = Referrals.toFallbackReferralEntryView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Referrals.toFallbackReferralEntryViews([item, item]).count == 2)
    }
}
