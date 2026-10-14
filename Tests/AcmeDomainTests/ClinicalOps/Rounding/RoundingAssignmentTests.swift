@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsRoundingAssignmentTests {
    @Test func startsInCreated() throws {
        let item = ClinicalOps.newRoundingAssignment("code-545", name: "name-823")
        #expect(item.status == ClinicalOps.RoundingAssignmentStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToRetired() throws {
        let item = ClinicalOps.newRoundingAssignment("code-545", name: "name-823")
        try item.moveTo(ClinicalOps.RoundingAssignmentStatus.retired)
        #expect(item.status == ClinicalOps.RoundingAssignmentStatus.retired)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = ClinicalOps.newRoundingAssignment("code-545", name: "name-823")
        item.status = ClinicalOps.RoundingAssignmentStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.RoundingAssignmentStatus.created) }
    }
}
