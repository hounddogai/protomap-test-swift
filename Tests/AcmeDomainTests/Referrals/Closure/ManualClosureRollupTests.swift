@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsManualClosureRollupTests {
    @Test func startsInPlanned() throws {
        let item = Referrals.newManualClosureRollup("code-955", title: "title-684")
        #expect(item.status == Referrals.ManualClosureRollupStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToCompleted() throws {
        let item = Referrals.newManualClosureRollup("code-955", title: "title-684")
        try item.moveTo(Referrals.ManualClosureRollupStatus.completed)
        #expect(item.status == Referrals.ManualClosureRollupStatus.completed)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Referrals.newManualClosureRollup("code-955", title: "title-684")
        item.status = Referrals.ManualClosureRollupStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.ManualClosureRollupStatus.planned) }
    }
}
