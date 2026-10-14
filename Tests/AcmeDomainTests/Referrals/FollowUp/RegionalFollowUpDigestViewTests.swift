@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsRegionalFollowUpDigestViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Referrals.newRegionalFollowUpDigest("code-780", title: "title-644")
        let view = Referrals.toRegionalFollowUpDigestView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Referrals.toRegionalFollowUpDigestViews([item, item]).count == 2)
    }
}
