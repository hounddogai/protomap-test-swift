@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsDefaultClosureEntryTests {
    @Test func startsInNew() throws {
        let item = Referrals.newDefaultClosureEntry("code-396", title: "title-453")
        #expect(item.status == Referrals.DefaultClosureEntryStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToDone() throws {
        let item = Referrals.newDefaultClosureEntry("code-396", title: "title-453")
        try item.moveTo(Referrals.DefaultClosureEntryStatus.done)
        #expect(item.status == Referrals.DefaultClosureEntryStatus.done)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Referrals.newDefaultClosureEntry("code-396", title: "title-453")
        item.status = Referrals.DefaultClosureEntryStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.DefaultClosureEntryStatus.new) }
    }
}
