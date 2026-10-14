@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsEligibilityAuditTests {
    @Test func startsInNew() throws {
        let item = Referrals.newEligibilityAudit("code-524", title: "title-332")
        #expect(item.status == Referrals.EligibilityAuditStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToQueued() throws {
        let item = Referrals.newEligibilityAudit("code-524", title: "title-332")
        try item.moveTo(Referrals.EligibilityAuditStatus.queued)
        #expect(item.status == Referrals.EligibilityAuditStatus.queued)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Referrals.newEligibilityAudit("code-524", title: "title-332")
        item.status = Referrals.EligibilityAuditStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.EligibilityAuditStatus.new) }
    }
}
