@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsGlobalEligibilityVarianceTests {
    @Test func startsInCreated() throws {
        let item = Referrals.newGlobalEligibilityVariance("code-440", title: "title-839")
        #expect(item.status == Referrals.GlobalEligibilityVarianceStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToPublished() throws {
        let item = Referrals.newGlobalEligibilityVariance("code-440", title: "title-839")
        try item.moveTo(Referrals.GlobalEligibilityVarianceStatus.published)
        #expect(item.status == Referrals.GlobalEligibilityVarianceStatus.published)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = Referrals.newGlobalEligibilityVariance("code-440", title: "title-839")
        item.status = Referrals.GlobalEligibilityVarianceStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.GlobalEligibilityVarianceStatus.created) }
    }
}
