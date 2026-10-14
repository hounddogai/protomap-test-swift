@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsPendingSlotTargetTests {
    @Test func startsInPlanned() throws {
        let item = Referrals.newPendingSlotTarget("code-657", name: "name-977")
        #expect(item.status == Referrals.PendingSlotTargetStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToScheduled() throws {
        let item = Referrals.newPendingSlotTarget("code-657", name: "name-977")
        try item.moveTo(Referrals.PendingSlotTargetStatus.scheduled)
        #expect(item.status == Referrals.PendingSlotTargetStatus.scheduled)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Referrals.newPendingSlotTarget("code-657", name: "name-977")
        item.status = Referrals.PendingSlotTargetStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.PendingSlotTargetStatus.planned) }
    }
}
