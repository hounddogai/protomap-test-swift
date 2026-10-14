@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsLegacyFollowUpAuditTests {
    @Test func startsInCreated() throws {
        let item = Referrals.newLegacyFollowUpAudit("code-7", label: "label-82")
        #expect(item.status == Referrals.LegacyFollowUpAuditStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToValidated() throws {
        let item = Referrals.newLegacyFollowUpAudit("code-7", label: "label-82")
        try item.moveTo(Referrals.LegacyFollowUpAuditStatus.validated)
        #expect(item.status == Referrals.LegacyFollowUpAuditStatus.validated)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = Referrals.newLegacyFollowUpAudit("code-7", label: "label-82")
        item.status = Referrals.LegacyFollowUpAuditStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.LegacyFollowUpAuditStatus.created) }
    }
}
