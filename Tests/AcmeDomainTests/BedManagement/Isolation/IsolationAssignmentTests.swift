@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementIsolationAssignmentTests {
    @Test func startsInRequested() throws {
        let item = BedManagement.newIsolationAssignment("code-432", label: "label-893")
        #expect(item.status == BedManagement.IsolationAssignmentStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToRevoked() throws {
        let item = BedManagement.newIsolationAssignment("code-432", label: "label-893")
        try item.moveTo(BedManagement.IsolationAssignmentStatus.revoked)
        #expect(item.status == BedManagement.IsolationAssignmentStatus.revoked)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = BedManagement.newIsolationAssignment("code-432", label: "label-893")
        item.status = BedManagement.IsolationAssignmentStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.IsolationAssignmentStatus.requested) }
    }
}
