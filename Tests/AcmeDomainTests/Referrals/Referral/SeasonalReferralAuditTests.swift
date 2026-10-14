@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsSeasonalReferralAuditTests {
    @Test func startsInCreated() throws {
        let item = Referrals.newSeasonalReferralAudit("code-468", label: "label-829")
        #expect(item.status == Referrals.SeasonalReferralAuditStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToValidated() throws {
        let item = Referrals.newSeasonalReferralAudit("code-468", label: "label-829")
        try item.moveTo(Referrals.SeasonalReferralAuditStatus.validated)
        #expect(item.status == Referrals.SeasonalReferralAuditStatus.validated)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = Referrals.newSeasonalReferralAudit("code-468", label: "label-829")
        item.status = Referrals.SeasonalReferralAuditStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.SeasonalReferralAuditStatus.created) }
    }
}
