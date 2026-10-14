@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsSeasonalEligibilityQuotaTests {
    @Test func startsInProposed() throws {
        let item = Referrals.newSeasonalEligibilityQuota("code-316", name: "name-77")
        #expect(item.status == Referrals.SeasonalEligibilityQuotaStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToRejected() throws {
        let item = Referrals.newSeasonalEligibilityQuota("code-316", name: "name-77")
        try item.moveTo(Referrals.SeasonalEligibilityQuotaStatus.rejected)
        #expect(item.status == Referrals.SeasonalEligibilityQuotaStatus.rejected)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Referrals.newSeasonalEligibilityQuota("code-316", name: "name-77")
        item.status = Referrals.SeasonalEligibilityQuotaStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.SeasonalEligibilityQuotaStatus.proposed) }
    }
}
