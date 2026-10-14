@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsReferralSlotViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Referrals.newReferralSlot("code-289", title: "title-856")
        let view = Referrals.toReferralSlotView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Referrals.toReferralSlotViews([item, item]).count == 2)
    }
}
