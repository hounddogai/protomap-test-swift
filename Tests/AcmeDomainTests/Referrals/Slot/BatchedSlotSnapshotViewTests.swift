@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsBatchedSlotSnapshotViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Referrals.newBatchedSlotSnapshot("code-593", title: "title-16")
        let view = Referrals.toBatchedSlotSnapshotView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Referrals.toBatchedSlotSnapshotViews([item, item]).count == 2)
    }
}
