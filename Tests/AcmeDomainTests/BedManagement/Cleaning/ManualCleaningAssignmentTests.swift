@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementManualCleaningAssignmentTests {
    @Test func startsInRequested() throws {
        let item = BedManagement.newManualCleaningAssignment("code-153", title: "title-95")
        #expect(item.status == BedManagement.ManualCleaningAssignmentStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToRevoked() throws {
        let item = BedManagement.newManualCleaningAssignment("code-153", title: "title-95")
        try item.moveTo(BedManagement.ManualCleaningAssignmentStatus.revoked)
        #expect(item.status == BedManagement.ManualCleaningAssignmentStatus.revoked)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = BedManagement.newManualCleaningAssignment("code-153", title: "title-95")
        item.status = BedManagement.ManualCleaningAssignmentStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.ManualCleaningAssignmentStatus.requested) }
    }
}
