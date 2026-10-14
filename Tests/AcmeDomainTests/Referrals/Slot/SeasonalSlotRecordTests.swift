@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsSeasonalSlotRecordTests {
    @Test func startsInDraft() throws {
        let item = Referrals.newSeasonalSlotRecord("code-320", name: "name-706")
        #expect(item.status == Referrals.SeasonalSlotRecordStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToPending() throws {
        let item = Referrals.newSeasonalSlotRecord("code-320", name: "name-706")
        try item.moveTo(Referrals.SeasonalSlotRecordStatus.pending)
        #expect(item.status == Referrals.SeasonalSlotRecordStatus.pending)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Referrals.newSeasonalSlotRecord("code-320", name: "name-706")
        item.status = Referrals.SeasonalSlotRecordStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.SeasonalSlotRecordStatus.draft) }
    }
}
