@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsBatchedClosureEstimateTests {
    @Test func startsInRequested() throws {
        let item = Referrals.newBatchedClosureEstimate("code-418", label: "label-754")
        #expect(item.status == Referrals.BatchedClosureEstimateStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToGranted() throws {
        let item = Referrals.newBatchedClosureEstimate("code-418", label: "label-754")
        try item.moveTo(Referrals.BatchedClosureEstimateStatus.granted)
        #expect(item.status == Referrals.BatchedClosureEstimateStatus.granted)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Referrals.newBatchedClosureEstimate("code-418", label: "label-754")
        item.status = Referrals.BatchedClosureEstimateStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.BatchedClosureEstimateStatus.requested) }
    }
}
