@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsSlotScoreTests {
    @Test func startsInPlanned() throws {
        let item = Referrals.newSlotScore("code-502", label: "label-127")
        #expect(item.status == Referrals.SlotScoreStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToScheduled() throws {
        let item = Referrals.newSlotScore("code-502", label: "label-127")
        try item.moveTo(Referrals.SlotScoreStatus.scheduled)
        #expect(item.status == Referrals.SlotScoreStatus.scheduled)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Referrals.newSlotScore("code-502", label: "label-127")
        item.status = Referrals.SlotScoreStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.SlotScoreStatus.planned) }
    }
}
