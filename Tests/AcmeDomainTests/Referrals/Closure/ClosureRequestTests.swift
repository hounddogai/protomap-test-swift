@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsClosureRequestTests {
    @Test func startsInProposed() throws {
        let item = Referrals.newClosureRequest("code-745", name: "name-576")
        #expect(item.status == Referrals.ClosureRequestStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToApproved() throws {
        let item = Referrals.newClosureRequest("code-745", name: "name-576")
        try item.moveTo(Referrals.ClosureRequestStatus.approved)
        #expect(item.status == Referrals.ClosureRequestStatus.approved)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Referrals.newClosureRequest("code-745", name: "name-576")
        item.status = Referrals.ClosureRequestStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.ClosureRequestStatus.proposed) }
    }
}
