@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsClosureEstimateTests {
    @Test func startsInRequested() throws {
        let item = Referrals.newClosureEstimate("code-332", name: "name-663")
        #expect(item.status == Referrals.ClosureEstimateStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToRevoked() throws {
        let item = Referrals.newClosureEstimate("code-332", name: "name-663")
        try item.moveTo(Referrals.ClosureEstimateStatus.revoked)
        #expect(item.status == Referrals.ClosureEstimateStatus.revoked)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Referrals.newClosureEstimate("code-332", name: "name-663")
        item.status = Referrals.ClosureEstimateStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.ClosureEstimateStatus.requested) }
    }
}
