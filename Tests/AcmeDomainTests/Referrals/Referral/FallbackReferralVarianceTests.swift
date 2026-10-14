@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsFallbackReferralVarianceTests {
    @Test func startsInNew() throws {
        let item = Referrals.newFallbackReferralVariance("code-937", title: "title-658")
        #expect(item.status == Referrals.FallbackReferralVarianceStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToDone() throws {
        let item = Referrals.newFallbackReferralVariance("code-937", title: "title-658")
        try item.moveTo(Referrals.FallbackReferralVarianceStatus.done)
        #expect(item.status == Referrals.FallbackReferralVarianceStatus.done)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Referrals.newFallbackReferralVariance("code-937", title: "title-658")
        item.status = Referrals.FallbackReferralVarianceStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.FallbackReferralVarianceStatus.new) }
    }
}
