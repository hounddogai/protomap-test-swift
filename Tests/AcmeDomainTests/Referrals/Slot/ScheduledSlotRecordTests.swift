@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsScheduledSlotRecordTests {
    @Test func startsInPlanned() throws {
        let item = Referrals.newScheduledSlotRecord("code-597", title: "title-786")
        #expect(item.status == Referrals.ScheduledSlotRecordStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToInProgress() throws {
        let item = Referrals.newScheduledSlotRecord("code-597", title: "title-786")
        try item.moveTo(Referrals.ScheduledSlotRecordStatus.inProgress)
        #expect(item.status == Referrals.ScheduledSlotRecordStatus.inProgress)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Referrals.newScheduledSlotRecord("code-597", title: "title-786")
        item.status = Referrals.ScheduledSlotRecordStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.ScheduledSlotRecordStatus.planned) }
    }
}
