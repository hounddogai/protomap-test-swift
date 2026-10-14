@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsClosureRollupTests {
    @Test func startsInOpen() throws {
        let item = Referrals.newClosureRollup("code-68", name: "name-968")
        #expect(item.status == Referrals.ClosureRollupStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToReopened() throws {
        let item = Referrals.newClosureRollup("code-68", name: "name-968")
        try item.moveTo(Referrals.ClosureRollupStatus.reopened)
        #expect(item.status == Referrals.ClosureRollupStatus.reopened)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = Referrals.newClosureRollup("code-68", name: "name-968")
        item.status = Referrals.ClosureRollupStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.ClosureRollupStatus.`open`) }
    }
}
