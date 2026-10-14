@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsRollingReferralAllocationTests {
    @Test func startsInNew() throws {
        let item = Referrals.newRollingReferralAllocation("code-566", title: "title-596")
        #expect(item.status == Referrals.RollingReferralAllocationStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToRunning() throws {
        let item = Referrals.newRollingReferralAllocation("code-566", title: "title-596")
        try item.moveTo(Referrals.RollingReferralAllocationStatus.running)
        #expect(item.status == Referrals.RollingReferralAllocationStatus.running)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Referrals.newRollingReferralAllocation("code-566", title: "title-596")
        item.status = Referrals.RollingReferralAllocationStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.RollingReferralAllocationStatus.new) }
    }
}
