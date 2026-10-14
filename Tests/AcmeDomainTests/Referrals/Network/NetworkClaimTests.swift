@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsNetworkClaimTests {
    @Test func startsInDraft() throws {
        let item = Referrals.newNetworkClaim("code-776", title: "title-745")
        #expect(item.status == Referrals.NetworkClaimStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToSuspended() throws {
        let item = Referrals.newNetworkClaim("code-776", title: "title-745")
        try item.moveTo(Referrals.NetworkClaimStatus.suspended)
        #expect(item.status == Referrals.NetworkClaimStatus.suspended)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Referrals.newNetworkClaim("code-776", title: "title-745")
        item.status = Referrals.NetworkClaimStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.NetworkClaimStatus.draft) }
    }
}
