@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsBatchedSlotTierTests {
    @Test func startsInCreated() throws {
        let item = Referrals.newBatchedSlotTier("code-219", title: "title-653")
        #expect(item.status == Referrals.BatchedSlotTierStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToValidated() throws {
        let item = Referrals.newBatchedSlotTier("code-219", title: "title-653")
        try item.moveTo(Referrals.BatchedSlotTierStatus.validated)
        #expect(item.status == Referrals.BatchedSlotTierStatus.validated)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = Referrals.newBatchedSlotTier("code-219", title: "title-653")
        item.status = Referrals.BatchedSlotTierStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.BatchedSlotTierStatus.created) }
    }
}
