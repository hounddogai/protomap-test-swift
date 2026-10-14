@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsGlobalReferralCycleViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Referrals.newGlobalReferralCycle("code-870", title: "title-611")
        let view = Referrals.toGlobalReferralCycleView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Referrals.toGlobalReferralCycleViews([item, item]).count == 2)
    }
}
