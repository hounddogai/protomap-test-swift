@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementCleaningAssignmentTests {
    @Test func startsInProposed() throws {
        let item = BedManagement.newCleaningAssignment("code-354", name: "name-404")
        #expect(item.status == BedManagement.CleaningAssignmentStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToApproved() throws {
        let item = BedManagement.newCleaningAssignment("code-354", name: "name-404")
        try item.moveTo(BedManagement.CleaningAssignmentStatus.approved)
        #expect(item.status == BedManagement.CleaningAssignmentStatus.approved)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = BedManagement.newCleaningAssignment("code-354", name: "name-404")
        item.status = BedManagement.CleaningAssignmentStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.CleaningAssignmentStatus.proposed) }
    }
}
