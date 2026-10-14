@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsEligibilityAssignmentTests {
    @Test func startsInNew() throws {
        let item = Referrals.newEligibilityAssignment("code-124", name: "name-90")
        #expect(item.status == Referrals.EligibilityAssignmentStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToRunning() throws {
        let item = Referrals.newEligibilityAssignment("code-124", name: "name-90")
        try item.moveTo(Referrals.EligibilityAssignmentStatus.running)
        #expect(item.status == Referrals.EligibilityAssignmentStatus.running)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Referrals.newEligibilityAssignment("code-124", name: "name-90")
        item.status = Referrals.EligibilityAssignmentStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.EligibilityAssignmentStatus.new) }
    }
}
