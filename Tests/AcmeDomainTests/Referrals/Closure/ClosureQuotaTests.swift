@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsClosureQuotaTests {
    @Test func startsInNew() throws {
        let item = Referrals.newClosureQuota("code-435", title: "title-616")
        #expect(item.status == Referrals.ClosureQuotaStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToRunning() throws {
        let item = Referrals.newClosureQuota("code-435", title: "title-616")
        try item.moveTo(Referrals.ClosureQuotaStatus.running)
        #expect(item.status == Referrals.ClosureQuotaStatus.running)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Referrals.newClosureQuota("code-435", title: "title-616")
        item.status = Referrals.ClosureQuotaStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.ClosureQuotaStatus.new) }
    }
}
