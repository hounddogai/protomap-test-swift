@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsCappedReferralSnapshotViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Referrals.newCappedReferralSnapshot("code-292", name: "name-745")
        let view = Referrals.toCappedReferralSnapshotView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Referrals.toCappedReferralSnapshotViews([item, item]).count == 2)
    }
}
