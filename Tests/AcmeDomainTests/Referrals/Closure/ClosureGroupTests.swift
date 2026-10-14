@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsClosureGroupTests {
    @Test func startsInNew() throws {
        let item = Referrals.newClosureGroup("code-441", title: "title-394")
        #expect(item.status == Referrals.ClosureGroupStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToDone() throws {
        let item = Referrals.newClosureGroup("code-441", title: "title-394")
        try item.moveTo(Referrals.ClosureGroupStatus.done)
        #expect(item.status == Referrals.ClosureGroupStatus.done)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Referrals.newClosureGroup("code-441", title: "title-394")
        item.status = Referrals.ClosureGroupStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.ClosureGroupStatus.new) }
    }
}
