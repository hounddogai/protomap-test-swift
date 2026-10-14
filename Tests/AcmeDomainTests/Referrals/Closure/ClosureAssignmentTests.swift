@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsClosureAssignmentTests {
    @Test func startsInNew() throws {
        let item = Referrals.newClosureAssignment("code-411", label: "label-394")
        #expect(item.status == Referrals.ClosureAssignmentStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToDone() throws {
        let item = Referrals.newClosureAssignment("code-411", label: "label-394")
        try item.moveTo(Referrals.ClosureAssignmentStatus.done)
        #expect(item.status == Referrals.ClosureAssignmentStatus.done)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Referrals.newClosureAssignment("code-411", label: "label-394")
        item.status = Referrals.ClosureAssignmentStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.ClosureAssignmentStatus.new) }
    }
}
