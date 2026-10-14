@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsWeightedClosureAdjustmentTests {
    @Test func startsInRequested() throws {
        let item = Referrals.newWeightedClosureAdjustment("code-461", name: "name-520")
        #expect(item.status == Referrals.WeightedClosureAdjustmentStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToRevoked() throws {
        let item = Referrals.newWeightedClosureAdjustment("code-461", name: "name-520")
        try item.moveTo(Referrals.WeightedClosureAdjustmentStatus.revoked)
        #expect(item.status == Referrals.WeightedClosureAdjustmentStatus.revoked)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Referrals.newWeightedClosureAdjustment("code-461", name: "name-520")
        item.status = Referrals.WeightedClosureAdjustmentStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.WeightedClosureAdjustmentStatus.requested) }
    }
}
