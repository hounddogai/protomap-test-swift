@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsPrimaryClosureAssignmentTests {
    @Test func startsInRequested() throws {
        let item = Referrals.newPrimaryClosureAssignment("code-918", title: "title-197")
        #expect(item.status == Referrals.PrimaryClosureAssignmentStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToGranted() throws {
        let item = Referrals.newPrimaryClosureAssignment("code-918", title: "title-197")
        try item.moveTo(Referrals.PrimaryClosureAssignmentStatus.granted)
        #expect(item.status == Referrals.PrimaryClosureAssignmentStatus.granted)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Referrals.newPrimaryClosureAssignment("code-918", title: "title-197")
        item.status = Referrals.PrimaryClosureAssignmentStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.PrimaryClosureAssignmentStatus.requested) }
    }
}
