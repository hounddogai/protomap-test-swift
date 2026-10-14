@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsBatchedNetworkClaimTests {
    @Test func startsInIdle() throws {
        let item = Referrals.newBatchedNetworkClaim("code-545", label: "label-679")
        #expect(item.status == Referrals.BatchedNetworkClaimStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToWarming() throws {
        let item = Referrals.newBatchedNetworkClaim("code-545", label: "label-679")
        try item.moveTo(Referrals.BatchedNetworkClaimStatus.warming)
        #expect(item.status == Referrals.BatchedNetworkClaimStatus.warming)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Referrals.newBatchedNetworkClaim("code-545", label: "label-679")
        item.status = Referrals.BatchedNetworkClaimStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.BatchedNetworkClaimStatus.idle) }
    }
}
