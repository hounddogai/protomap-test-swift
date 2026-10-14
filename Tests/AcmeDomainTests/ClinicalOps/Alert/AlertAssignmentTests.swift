@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsAlertAssignmentTests {
    @Test func startsInOpen() throws {
        let item = ClinicalOps.newAlertAssignment("code-28", title: "title-782")
        #expect(item.status == ClinicalOps.AlertAssignmentStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToResolved() throws {
        let item = ClinicalOps.newAlertAssignment("code-28", title: "title-782")
        try item.moveTo(ClinicalOps.AlertAssignmentStatus.resolved)
        #expect(item.status == ClinicalOps.AlertAssignmentStatus.resolved)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = ClinicalOps.newAlertAssignment("code-28", title: "title-782")
        item.status = ClinicalOps.AlertAssignmentStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.AlertAssignmentStatus.`open`) }
    }
}
