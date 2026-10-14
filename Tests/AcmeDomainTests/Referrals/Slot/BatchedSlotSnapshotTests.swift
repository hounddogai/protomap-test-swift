@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsBatchedSlotSnapshotTests {
    @Test func startsInPlanned() throws {
        let item = Referrals.newBatchedSlotSnapshot("code-593", title: "title-16")
        #expect(item.status == Referrals.BatchedSlotSnapshotStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToCompleted() throws {
        let item = Referrals.newBatchedSlotSnapshot("code-593", title: "title-16")
        try item.moveTo(Referrals.BatchedSlotSnapshotStatus.completed)
        #expect(item.status == Referrals.BatchedSlotSnapshotStatus.completed)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Referrals.newBatchedSlotSnapshot("code-593", title: "title-16")
        item.status = Referrals.BatchedSlotSnapshotStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.BatchedSlotSnapshotStatus.planned) }
    }
}
