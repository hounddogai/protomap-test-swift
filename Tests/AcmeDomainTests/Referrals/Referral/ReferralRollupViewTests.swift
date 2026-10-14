@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsReferralRollupViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Referrals.newReferralRollup("code-959", label: "label-641")
        let view = Referrals.toReferralRollupView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Referrals.toReferralRollupViews([item, item]).count == 2)
    }
}
