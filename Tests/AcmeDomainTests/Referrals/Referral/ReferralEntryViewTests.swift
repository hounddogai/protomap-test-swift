@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsReferralEntryViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Referrals.newReferralEntry("code-993", name: "name-143")
        let view = Referrals.toReferralEntryView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Referrals.toReferralEntryViews([item, item]).count == 2)
    }
}
