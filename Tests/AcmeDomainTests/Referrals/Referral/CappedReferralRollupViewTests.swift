@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsCappedReferralRollupViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Referrals.newCappedReferralRollup("code-421", title: "title-276")
        let view = Referrals.toCappedReferralRollupView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Referrals.toCappedReferralRollupViews([item, item]).count == 2)
    }
}
