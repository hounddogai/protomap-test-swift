@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsLenientSlotDigestViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Referrals.newLenientSlotDigest("code-959", title: "title-316")
        let view = Referrals.toLenientSlotDigestView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Referrals.toLenientSlotDigestViews([item, item]).count == 2)
    }
}
