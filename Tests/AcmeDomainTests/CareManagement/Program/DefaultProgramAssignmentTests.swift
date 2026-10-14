@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementDefaultProgramAssignmentTests {
    @Test func startsInCreated() throws {
        let item = CareManagement.newDefaultProgramAssignment("code-458", title: "title-326")
        #expect(item.status == CareManagement.DefaultProgramAssignmentStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToRetired() throws {
        let item = CareManagement.newDefaultProgramAssignment("code-458", title: "title-326")
        try item.moveTo(CareManagement.DefaultProgramAssignmentStatus.retired)
        #expect(item.status == CareManagement.DefaultProgramAssignmentStatus.retired)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = CareManagement.newDefaultProgramAssignment("code-458", title: "title-326")
        item.status = CareManagement.DefaultProgramAssignmentStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.DefaultProgramAssignmentStatus.created) }
    }
}
