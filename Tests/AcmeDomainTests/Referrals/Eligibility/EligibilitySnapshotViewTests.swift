@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsEligibilitySnapshotViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Referrals.newEligibilitySnapshot("code-844", label: "label-340")
        let view = Referrals.toEligibilitySnapshotView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Referrals.toEligibilitySnapshotViews([item, item]).count == 2)
    }
}
