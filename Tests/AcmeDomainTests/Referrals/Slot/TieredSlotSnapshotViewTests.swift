@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsTieredSlotSnapshotViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Referrals.newTieredSlotSnapshot("code-358", name: "name-812")
        let view = Referrals.toTieredSlotSnapshotView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Referrals.toTieredSlotSnapshotViews([item, item]).count == 2)
    }
}
