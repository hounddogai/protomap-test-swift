@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsTieredSlotSnapshotTests {
    @Test func startsInDraft() throws {
        let item = Referrals.newTieredSlotSnapshot("code-358", name: "name-812")
        #expect(item.status == Referrals.TieredSlotSnapshotStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToPending() throws {
        let item = Referrals.newTieredSlotSnapshot("code-358", name: "name-812")
        try item.moveTo(Referrals.TieredSlotSnapshotStatus.pending)
        #expect(item.status == Referrals.TieredSlotSnapshotStatus.pending)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Referrals.newTieredSlotSnapshot("code-358", name: "name-812")
        item.status = Referrals.TieredSlotSnapshotStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.TieredSlotSnapshotStatus.draft) }
    }
}
