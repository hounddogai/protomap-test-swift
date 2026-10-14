@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsLegacyReferralClaimTests {
    @Test func startsInOpen() throws {
        let item = Referrals.newLegacyReferralClaim("code-281", name: "name-62")
        #expect(item.status == Referrals.LegacyReferralClaimStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToReopened() throws {
        let item = Referrals.newLegacyReferralClaim("code-281", name: "name-62")
        try item.moveTo(Referrals.LegacyReferralClaimStatus.reopened)
        #expect(item.status == Referrals.LegacyReferralClaimStatus.reopened)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = Referrals.newLegacyReferralClaim("code-281", name: "name-62")
        item.status = Referrals.LegacyReferralClaimStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.LegacyReferralClaimStatus.`open`) }
    }
}
