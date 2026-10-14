@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsLegacySlotRecordTests {
    @Test func startsInDraft() throws {
        let item = Referrals.newLegacySlotRecord("code-527", title: "title-928")
        #expect(item.status == Referrals.LegacySlotRecordStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToPending() throws {
        let item = Referrals.newLegacySlotRecord("code-527", title: "title-928")
        try item.moveTo(Referrals.LegacySlotRecordStatus.pending)
        #expect(item.status == Referrals.LegacySlotRecordStatus.pending)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Referrals.newLegacySlotRecord("code-527", title: "title-928")
        item.status = Referrals.LegacySlotRecordStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.LegacySlotRecordStatus.draft) }
    }
}
