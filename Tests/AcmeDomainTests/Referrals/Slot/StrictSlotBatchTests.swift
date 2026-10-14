@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsStrictSlotBatchTests {
    @Test func startsInOpen() throws {
        let item = Referrals.newStrictSlotBatch("code-351", label: "label-545")
        #expect(item.status == Referrals.StrictSlotBatchStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToReopened() throws {
        let item = Referrals.newStrictSlotBatch("code-351", label: "label-545")
        try item.moveTo(Referrals.StrictSlotBatchStatus.reopened)
        #expect(item.status == Referrals.StrictSlotBatchStatus.reopened)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = Referrals.newStrictSlotBatch("code-351", label: "label-545")
        item.status = Referrals.StrictSlotBatchStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.StrictSlotBatchStatus.`open`) }
    }
}
