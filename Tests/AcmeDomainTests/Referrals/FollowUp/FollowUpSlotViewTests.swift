@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsFollowUpSlotViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Referrals.newFollowUpSlot("code-416", title: "title-913")
        let view = Referrals.toFollowUpSlotView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Referrals.toFollowUpSlotViews([item, item]).count == 2)
    }
}
