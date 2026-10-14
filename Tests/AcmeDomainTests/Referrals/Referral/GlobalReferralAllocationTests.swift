@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsGlobalReferralAllocationTests {
    @Test func startsInOpen() throws {
        let item = Referrals.newGlobalReferralAllocation("code-401", label: "label-788")
        #expect(item.status == Referrals.GlobalReferralAllocationStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToInReview() throws {
        let item = Referrals.newGlobalReferralAllocation("code-401", label: "label-788")
        try item.moveTo(Referrals.GlobalReferralAllocationStatus.inReview)
        #expect(item.status == Referrals.GlobalReferralAllocationStatus.inReview)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = Referrals.newGlobalReferralAllocation("code-401", label: "label-788")
        item.status = Referrals.GlobalReferralAllocationStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.GlobalReferralAllocationStatus.`open`) }
    }
}
