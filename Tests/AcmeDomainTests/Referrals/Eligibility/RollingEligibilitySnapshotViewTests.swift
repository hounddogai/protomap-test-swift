@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsRollingEligibilitySnapshotViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Referrals.newRollingEligibilitySnapshot("code-801", name: "name-511")
        let view = Referrals.toRollingEligibilitySnapshotView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Referrals.toRollingEligibilitySnapshotViews([item, item]).count == 2)
    }
}
