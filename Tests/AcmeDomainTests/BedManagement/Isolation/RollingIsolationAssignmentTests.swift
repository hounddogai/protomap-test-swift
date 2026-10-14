@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementRollingIsolationAssignmentTests {
    @Test func startsInPlanned() throws {
        let item = BedManagement.newRollingIsolationAssignment("code-337", name: "name-264")
        #expect(item.status == BedManagement.RollingIsolationAssignmentStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToScheduled() throws {
        let item = BedManagement.newRollingIsolationAssignment("code-337", name: "name-264")
        try item.moveTo(BedManagement.RollingIsolationAssignmentStatus.scheduled)
        #expect(item.status == BedManagement.RollingIsolationAssignmentStatus.scheduled)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = BedManagement.newRollingIsolationAssignment("code-337", name: "name-264")
        item.status = BedManagement.RollingIsolationAssignmentStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.RollingIsolationAssignmentStatus.planned) }
    }
}
