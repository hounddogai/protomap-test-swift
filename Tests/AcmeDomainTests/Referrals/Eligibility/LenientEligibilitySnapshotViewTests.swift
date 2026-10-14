@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsLenientEligibilitySnapshotViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Referrals.newLenientEligibilitySnapshot("code-565", label: "label-616")
        let view = Referrals.toLenientEligibilitySnapshotView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Referrals.toLenientEligibilitySnapshotViews([item, item]).count == 2)
    }
}
