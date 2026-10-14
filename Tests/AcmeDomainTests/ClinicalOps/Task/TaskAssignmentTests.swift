@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsTaskAssignmentTests {
    @Test func startsInCreated() throws {
        let item = ClinicalOps.newTaskAssignment("code-636", name: "name-603")
        #expect(item.status == ClinicalOps.TaskAssignmentStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToPublished() throws {
        let item = ClinicalOps.newTaskAssignment("code-636", name: "name-603")
        try item.moveTo(ClinicalOps.TaskAssignmentStatus.published)
        #expect(item.status == ClinicalOps.TaskAssignmentStatus.published)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = ClinicalOps.newTaskAssignment("code-636", name: "name-603")
        item.status = ClinicalOps.TaskAssignmentStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.TaskAssignmentStatus.created) }
    }
}
