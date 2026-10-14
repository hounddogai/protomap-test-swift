@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsDefaultSlotRequestViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Referrals.newDefaultSlotRequest("code-446", label: "label-938")
        let view = Referrals.toDefaultSlotRequestView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Referrals.toDefaultSlotRequestViews([item, item]).count == 2)
    }
}
