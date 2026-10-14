@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsFallbackNetworkSnapshotViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Referrals.newFallbackNetworkSnapshot("code-820", title: "title-45")
        let view = Referrals.toFallbackNetworkSnapshotView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Referrals.toFallbackNetworkSnapshotViews([item, item]).count == 2)
    }
}
