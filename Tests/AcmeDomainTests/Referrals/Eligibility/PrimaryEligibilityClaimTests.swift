@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsPrimaryEligibilityClaimTests {
    @Test func startsInNew() throws {
        let item = Referrals.newPrimaryEligibilityClaim("code-401", name: "name-925")
        #expect(item.status == Referrals.PrimaryEligibilityClaimStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToFailed() throws {
        let item = Referrals.newPrimaryEligibilityClaim("code-401", name: "name-925")
        try item.moveTo(Referrals.PrimaryEligibilityClaimStatus.failed)
        #expect(item.status == Referrals.PrimaryEligibilityClaimStatus.failed)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Referrals.newPrimaryEligibilityClaim("code-401", name: "name-925")
        item.status = Referrals.PrimaryEligibilityClaimStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.PrimaryEligibilityClaimStatus.new) }
    }
}
