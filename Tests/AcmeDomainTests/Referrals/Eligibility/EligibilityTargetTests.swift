@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsEligibilityTargetTests {
    @Test func startsInPlanned() throws {
        let item = Referrals.newEligibilityTarget("code-852", name: "name-47")
        #expect(item.status == Referrals.EligibilityTargetStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToScheduled() throws {
        let item = Referrals.newEligibilityTarget("code-852", name: "name-47")
        try item.moveTo(Referrals.EligibilityTargetStatus.scheduled)
        #expect(item.status == Referrals.EligibilityTargetStatus.scheduled)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Referrals.newEligibilityTarget("code-852", name: "name-47")
        item.status = Referrals.EligibilityTargetStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.EligibilityTargetStatus.planned) }
    }
}
