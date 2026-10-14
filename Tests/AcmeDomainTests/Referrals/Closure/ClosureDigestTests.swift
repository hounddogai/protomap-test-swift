@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsClosureDigestTests {
    @Test func startsInRequested() throws {
        let item = Referrals.newClosureDigest("code-214", label: "label-507")
        #expect(item.status == Referrals.ClosureDigestStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToRevoked() throws {
        let item = Referrals.newClosureDigest("code-214", label: "label-507")
        try item.moveTo(Referrals.ClosureDigestStatus.revoked)
        #expect(item.status == Referrals.ClosureDigestStatus.revoked)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Referrals.newClosureDigest("code-214", label: "label-507")
        item.status = Referrals.ClosureDigestStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.ClosureDigestStatus.requested) }
    }
}
