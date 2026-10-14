@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsLenientNetworkSnapshotViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Referrals.newLenientNetworkSnapshot("code-372", name: "name-711")
        let view = Referrals.toLenientNetworkSnapshotView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Referrals.toLenientNetworkSnapshotViews([item, item]).count == 2)
    }
}
