@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsBatchedSlotRecordTests {
    @Test func startsInRequested() throws {
        let item = Referrals.newBatchedSlotRecord("code-275", title: "title-891")
        #expect(item.status == Referrals.BatchedSlotRecordStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToGranted() throws {
        let item = Referrals.newBatchedSlotRecord("code-275", title: "title-891")
        try item.moveTo(Referrals.BatchedSlotRecordStatus.granted)
        #expect(item.status == Referrals.BatchedSlotRecordStatus.granted)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Referrals.newBatchedSlotRecord("code-275", title: "title-891")
        item.status = Referrals.BatchedSlotRecordStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.BatchedSlotRecordStatus.requested) }
    }
}
