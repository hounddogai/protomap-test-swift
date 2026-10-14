@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsWeightedReferralExceptionTests {
    @Test func startsInIdle() throws {
        let item = Referrals.newWeightedReferralException("code-29", title: "title-324")
        #expect(item.status == Referrals.WeightedReferralExceptionStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToStopped() throws {
        let item = Referrals.newWeightedReferralException("code-29", title: "title-324")
        try item.moveTo(Referrals.WeightedReferralExceptionStatus.stopped)
        #expect(item.status == Referrals.WeightedReferralExceptionStatus.stopped)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Referrals.newWeightedReferralException("code-29", title: "title-324")
        item.status = Referrals.WeightedReferralExceptionStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.WeightedReferralExceptionStatus.idle) }
    }
}
