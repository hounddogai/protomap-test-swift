@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsManualClosureScoreTests {
    @Test func startsInPlanned() throws {
        let item = Referrals.newManualClosureScore("code-161", label: "label-611")
        #expect(item.status == Referrals.ManualClosureScoreStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToCompleted() throws {
        let item = Referrals.newManualClosureScore("code-161", label: "label-611")
        try item.moveTo(Referrals.ManualClosureScoreStatus.completed)
        #expect(item.status == Referrals.ManualClosureScoreStatus.completed)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Referrals.newManualClosureScore("code-161", label: "label-611")
        item.status = Referrals.ManualClosureScoreStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.ManualClosureScoreStatus.planned) }
    }
}
