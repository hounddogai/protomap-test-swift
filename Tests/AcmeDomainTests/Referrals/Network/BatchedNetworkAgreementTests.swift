@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsBatchedNetworkAgreementTests {
    @Test func startsInIdle() throws {
        let item = Referrals.newBatchedNetworkAgreement("code-181", label: "label-145")
        #expect(item.status == Referrals.BatchedNetworkAgreementStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToWarming() throws {
        let item = Referrals.newBatchedNetworkAgreement("code-181", label: "label-145")
        try item.moveTo(Referrals.BatchedNetworkAgreementStatus.warming)
        #expect(item.status == Referrals.BatchedNetworkAgreementStatus.warming)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Referrals.newBatchedNetworkAgreement("code-181", label: "label-145")
        item.status = Referrals.BatchedNetworkAgreementStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.BatchedNetworkAgreementStatus.idle) }
    }
}
