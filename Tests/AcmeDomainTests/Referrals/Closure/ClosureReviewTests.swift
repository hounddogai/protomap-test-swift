@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsClosureReviewTests {
    @Test func startsInProposed() throws {
        let item = Referrals.newClosureReview("code-943", name: "name-445")
        #expect(item.status == Referrals.ClosureReviewStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToApproved() throws {
        let item = Referrals.newClosureReview("code-943", name: "name-445")
        try item.moveTo(Referrals.ClosureReviewStatus.approved)
        #expect(item.status == Referrals.ClosureReviewStatus.approved)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Referrals.newClosureReview("code-943", name: "name-445")
        item.status = Referrals.ClosureReviewStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.ClosureReviewStatus.proposed) }
    }
}
