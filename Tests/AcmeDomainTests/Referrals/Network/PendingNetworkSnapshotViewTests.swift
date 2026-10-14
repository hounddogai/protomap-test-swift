@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsPendingNetworkSnapshotViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Referrals.newPendingNetworkSnapshot("code-220", title: "title-599")
        let view = Referrals.toPendingNetworkSnapshotView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Referrals.toPendingNetworkSnapshotViews([item, item]).count == 2)
    }
}
