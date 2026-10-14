@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsSlotSnapshotTests {
    @Test func startsInDraft() throws {
        let item = Referrals.newSlotSnapshot("code-914", label: "label-640")
        #expect(item.status == Referrals.SlotSnapshotStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToPending() throws {
        let item = Referrals.newSlotSnapshot("code-914", label: "label-640")
        try item.moveTo(Referrals.SlotSnapshotStatus.pending)
        #expect(item.status == Referrals.SlotSnapshotStatus.pending)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Referrals.newSlotSnapshot("code-914", label: "label-640")
        item.status = Referrals.SlotSnapshotStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.SlotSnapshotStatus.draft) }
    }
}
