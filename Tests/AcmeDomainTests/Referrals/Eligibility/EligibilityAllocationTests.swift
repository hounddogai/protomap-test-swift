@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsEligibilityAllocationTests {
    @Test func startsInPlanned() throws {
        let item = Referrals.newEligibilityAllocation("code-567", title: "title-200")
        #expect(item.status == Referrals.EligibilityAllocationStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToScheduled() throws {
        let item = Referrals.newEligibilityAllocation("code-567", title: "title-200")
        try item.moveTo(Referrals.EligibilityAllocationStatus.scheduled)
        #expect(item.status == Referrals.EligibilityAllocationStatus.scheduled)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Referrals.newEligibilityAllocation("code-567", title: "title-200")
        item.status = Referrals.EligibilityAllocationStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.EligibilityAllocationStatus.planned) }
    }
}
