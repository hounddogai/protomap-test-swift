@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsGlobalOrderSetAssignmentTests {
    @Test func startsInOpen() throws {
        let item = ClinicalOps.newGlobalOrderSetAssignment("code-206", name: "name-713")
        #expect(item.status == ClinicalOps.GlobalOrderSetAssignmentStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToReopened() throws {
        let item = ClinicalOps.newGlobalOrderSetAssignment("code-206", name: "name-713")
        try item.moveTo(ClinicalOps.GlobalOrderSetAssignmentStatus.reopened)
        #expect(item.status == ClinicalOps.GlobalOrderSetAssignmentStatus.reopened)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = ClinicalOps.newGlobalOrderSetAssignment("code-206", name: "name-713")
        item.status = ClinicalOps.GlobalOrderSetAssignmentStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.GlobalOrderSetAssignmentStatus.`open`) }
    }
}
