@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsReferralSnapshotViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Referrals.newReferralSnapshot("code-262", title: "title-191")
        let view = Referrals.toReferralSnapshotView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Referrals.toReferralSnapshotViews([item, item]).count == 2)
    }
}
