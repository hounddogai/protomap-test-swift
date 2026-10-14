@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementProgramAssignmentTests {
    @Test func startsInDraft() throws {
        let item = CareManagement.newProgramAssignment("code-526", title: "title-514")
        #expect(item.status == CareManagement.ProgramAssignmentStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToSuspended() throws {
        let item = CareManagement.newProgramAssignment("code-526", title: "title-514")
        try item.moveTo(CareManagement.ProgramAssignmentStatus.suspended)
        #expect(item.status == CareManagement.ProgramAssignmentStatus.suspended)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = CareManagement.newProgramAssignment("code-526", title: "title-514")
        item.status = CareManagement.ProgramAssignmentStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.ProgramAssignmentStatus.draft) }
    }
}
