@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsPendingCourierAssignmentTests {
    @Test func startsInRequested() throws {
        let item = Labs.newPendingCourierAssignment("code-329", name: "name-263")
        #expect(item.status == Labs.PendingCourierAssignmentStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToRevoked() throws {
        let item = Labs.newPendingCourierAssignment("code-329", name: "name-263")
        try item.moveTo(Labs.PendingCourierAssignmentStatus.revoked)
        #expect(item.status == Labs.PendingCourierAssignmentStatus.revoked)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Labs.newPendingCourierAssignment("code-329", name: "name-263")
        item.status = Labs.PendingCourierAssignmentStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Labs.PendingCourierAssignmentStatus.requested) }
    }
}
