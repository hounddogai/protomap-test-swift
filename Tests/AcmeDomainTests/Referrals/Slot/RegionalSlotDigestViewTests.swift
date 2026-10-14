@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsRegionalSlotDigestViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Referrals.newRegionalSlotDigest("code-306", label: "label-960")
        let view = Referrals.toRegionalSlotDigestView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Referrals.toRegionalSlotDigestViews([item, item]).count == 2)
    }
}
