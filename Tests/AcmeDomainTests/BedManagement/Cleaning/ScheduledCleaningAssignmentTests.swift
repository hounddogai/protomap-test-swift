@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementScheduledCleaningAssignmentTests {
    @Test func startsInRequested() throws {
        let item = BedManagement.newScheduledCleaningAssignment("code-271", name: "name-319")
        #expect(item.status == BedManagement.ScheduledCleaningAssignmentStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToGranted() throws {
        let item = BedManagement.newScheduledCleaningAssignment("code-271", name: "name-319")
        try item.moveTo(BedManagement.ScheduledCleaningAssignmentStatus.granted)
        #expect(item.status == BedManagement.ScheduledCleaningAssignmentStatus.granted)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = BedManagement.newScheduledCleaningAssignment("code-271", name: "name-319")
        item.status = BedManagement.ScheduledCleaningAssignmentStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.ScheduledCleaningAssignmentStatus.requested) }
    }
}
