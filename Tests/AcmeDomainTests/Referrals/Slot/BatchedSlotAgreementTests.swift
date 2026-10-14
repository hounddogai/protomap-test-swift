@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsBatchedSlotAgreementTests {
    @Test func startsInPlanned() throws {
        let item = Referrals.newBatchedSlotAgreement("code-870", title: "title-100")
        #expect(item.status == Referrals.BatchedSlotAgreementStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToInProgress() throws {
        let item = Referrals.newBatchedSlotAgreement("code-870", title: "title-100")
        try item.moveTo(Referrals.BatchedSlotAgreementStatus.inProgress)
        #expect(item.status == Referrals.BatchedSlotAgreementStatus.inProgress)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Referrals.newBatchedSlotAgreement("code-870", title: "title-100")
        item.status = Referrals.BatchedSlotAgreementStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.BatchedSlotAgreementStatus.planned) }
    }
}
