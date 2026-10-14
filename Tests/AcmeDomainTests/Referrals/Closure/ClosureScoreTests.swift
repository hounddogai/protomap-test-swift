@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsClosureScoreTests {
    @Test func startsInDraft() throws {
        let item = Referrals.newClosureScore("code-960", title: "title-968")
        #expect(item.status == Referrals.ClosureScoreStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToPending() throws {
        let item = Referrals.newClosureScore("code-960", title: "title-968")
        try item.moveTo(Referrals.ClosureScoreStatus.pending)
        #expect(item.status == Referrals.ClosureScoreStatus.pending)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Referrals.newClosureScore("code-960", title: "title-968")
        item.status = Referrals.ClosureScoreStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.ClosureScoreStatus.draft) }
    }
}
