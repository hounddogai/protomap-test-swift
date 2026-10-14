@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsSlotProfileViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Referrals.newSlotProfile("code-267", title: "title-316")
        let view = Referrals.toSlotProfileView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Referrals.toSlotProfileViews([item, item]).count == 2)
    }
}
