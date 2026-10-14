@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsFollowUpEstimateTests {
    @Test func startsInPlanned() throws {
        let item = Referrals.newFollowUpEstimate("code-275", label: "label-361")
        #expect(item.status == Referrals.FollowUpEstimateStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToCompleted() throws {
        let item = Referrals.newFollowUpEstimate("code-275", label: "label-361")
        try item.moveTo(Referrals.FollowUpEstimateStatus.completed)
        #expect(item.status == Referrals.FollowUpEstimateStatus.completed)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Referrals.newFollowUpEstimate("code-275", label: "label-361")
        item.status = Referrals.FollowUpEstimateStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.FollowUpEstimateStatus.planned) }
    }
}
