@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsFollowUpLedgerTests {
    @Test func startsInNew() throws {
        let item = Referrals.newFollowUpLedger("code-760", name: "name-677")
        #expect(item.status == Referrals.FollowUpLedgerStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToQueued() throws {
        let item = Referrals.newFollowUpLedger("code-760", name: "name-677")
        try item.moveTo(Referrals.FollowUpLedgerStatus.queued)
        #expect(item.status == Referrals.FollowUpLedgerStatus.queued)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Referrals.newFollowUpLedger("code-760", name: "name-677")
        item.status = Referrals.FollowUpLedgerStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.FollowUpLedgerStatus.new) }
    }
}
