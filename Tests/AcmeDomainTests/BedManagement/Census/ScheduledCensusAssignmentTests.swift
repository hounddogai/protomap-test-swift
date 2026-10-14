@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementScheduledCensusAssignmentTests {
    @Test func startsInIdle() throws {
        let item = BedManagement.newScheduledCensusAssignment("code-968", label: "label-904")
        #expect(item.status == BedManagement.ScheduledCensusAssignmentStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToWarming() throws {
        let item = BedManagement.newScheduledCensusAssignment("code-968", label: "label-904")
        try item.moveTo(BedManagement.ScheduledCensusAssignmentStatus.warming)
        #expect(item.status == BedManagement.ScheduledCensusAssignmentStatus.warming)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = BedManagement.newScheduledCensusAssignment("code-968", label: "label-904")
        item.status = BedManagement.ScheduledCensusAssignmentStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.ScheduledCensusAssignmentStatus.idle) }
    }
}
