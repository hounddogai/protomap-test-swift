@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsClosureProfileTests {
    @Test func startsInNew() throws {
        let item = Referrals.newClosureProfile("code-567", title: "title-73")
        #expect(item.status == Referrals.ClosureProfileStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToQueued() throws {
        let item = Referrals.newClosureProfile("code-567", title: "title-73")
        try item.moveTo(Referrals.ClosureProfileStatus.queued)
        #expect(item.status == Referrals.ClosureProfileStatus.queued)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Referrals.newClosureProfile("code-567", title: "title-73")
        item.status = Referrals.ClosureProfileStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.ClosureProfileStatus.new) }
    }
}
