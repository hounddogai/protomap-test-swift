@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsReferralMappingTests {
    @Test func startsInOpen() throws {
        let item = Referrals.newReferralMapping("code-396", name: "name-719")
        #expect(item.status == Referrals.ReferralMappingStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToReopened() throws {
        let item = Referrals.newReferralMapping("code-396", name: "name-719")
        try item.moveTo(Referrals.ReferralMappingStatus.reopened)
        #expect(item.status == Referrals.ReferralMappingStatus.reopened)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = Referrals.newReferralMapping("code-396", name: "name-719")
        item.status = Referrals.ReferralMappingStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.ReferralMappingStatus.`open`) }
    }
}
