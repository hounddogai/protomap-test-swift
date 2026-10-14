@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsRegionalFollowUpDigestTests {
    @Test func startsInProposed() throws {
        let item = Referrals.newRegionalFollowUpDigest("code-780", title: "title-644")
        #expect(item.status == Referrals.RegionalFollowUpDigestStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToWithdrawn() throws {
        let item = Referrals.newRegionalFollowUpDigest("code-780", title: "title-644")
        try item.moveTo(Referrals.RegionalFollowUpDigestStatus.withdrawn)
        #expect(item.status == Referrals.RegionalFollowUpDigestStatus.withdrawn)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Referrals.newRegionalFollowUpDigest("code-780", title: "title-644")
        item.status = Referrals.RegionalFollowUpDigestStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.RegionalFollowUpDigestStatus.proposed) }
    }
}
