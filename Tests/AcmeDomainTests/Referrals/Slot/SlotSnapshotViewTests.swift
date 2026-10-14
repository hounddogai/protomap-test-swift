@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsSlotSnapshotViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Referrals.newSlotSnapshot("code-914", label: "label-640")
        let view = Referrals.toSlotSnapshotView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Referrals.toSlotSnapshotViews([item, item]).count == 2)
    }
}
