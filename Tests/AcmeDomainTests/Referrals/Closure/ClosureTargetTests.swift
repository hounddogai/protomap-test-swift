@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsClosureTargetTests {
    @Test func startsInRequested() throws {
        let item = Referrals.newClosureTarget("code-512", title: "title-597")
        #expect(item.status == Referrals.ClosureTargetStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToRevoked() throws {
        let item = Referrals.newClosureTarget("code-512", title: "title-597")
        try item.moveTo(Referrals.ClosureTargetStatus.revoked)
        #expect(item.status == Referrals.ClosureTargetStatus.revoked)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Referrals.newClosureTarget("code-512", title: "title-597")
        item.status = Referrals.ClosureTargetStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.ClosureTargetStatus.requested) }
    }
}
