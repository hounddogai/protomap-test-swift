@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsEligibilityDigestTests {
    @Test func startsInCreated() throws {
        let item = Referrals.newEligibilityDigest("code-720", label: "label-462")
        #expect(item.status == Referrals.EligibilityDigestStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToPublished() throws {
        let item = Referrals.newEligibilityDigest("code-720", label: "label-462")
        try item.moveTo(Referrals.EligibilityDigestStatus.published)
        #expect(item.status == Referrals.EligibilityDigestStatus.published)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = Referrals.newEligibilityDigest("code-720", label: "label-462")
        item.status = Referrals.EligibilityDigestStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.EligibilityDigestStatus.created) }
    }
}
