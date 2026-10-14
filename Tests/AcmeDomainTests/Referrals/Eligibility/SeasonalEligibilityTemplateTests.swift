@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsSeasonalEligibilityTemplateTests {
    @Test func startsInRequested() throws {
        let item = Referrals.newSeasonalEligibilityTemplate("code-814", name: "name-994")
        #expect(item.status == Referrals.SeasonalEligibilityTemplateStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToRevoked() throws {
        let item = Referrals.newSeasonalEligibilityTemplate("code-814", name: "name-994")
        try item.moveTo(Referrals.SeasonalEligibilityTemplateStatus.revoked)
        #expect(item.status == Referrals.SeasonalEligibilityTemplateStatus.revoked)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Referrals.newSeasonalEligibilityTemplate("code-814", name: "name-994")
        item.status = Referrals.SeasonalEligibilityTemplateStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.SeasonalEligibilityTemplateStatus.requested) }
    }
}
