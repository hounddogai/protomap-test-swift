@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsStrictSlotRecordTests {
    @Test func startsInDraft() throws {
        let item = Referrals.newStrictSlotRecord("code-79", label: "label-582")
        #expect(item.status == Referrals.StrictSlotRecordStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToPending() throws {
        let item = Referrals.newStrictSlotRecord("code-79", label: "label-582")
        try item.moveTo(Referrals.StrictSlotRecordStatus.pending)
        #expect(item.status == Referrals.StrictSlotRecordStatus.pending)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Referrals.newStrictSlotRecord("code-79", label: "label-582")
        item.status = Referrals.StrictSlotRecordStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.StrictSlotRecordStatus.draft) }
    }
}
