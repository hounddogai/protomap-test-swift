@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsOrderSetAssignmentTests {
    @Test func startsInDraft() throws {
        let item = ClinicalOps.newOrderSetAssignment("code-823", name: "name-478")
        #expect(item.status == ClinicalOps.OrderSetAssignmentStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToActive() throws {
        let item = ClinicalOps.newOrderSetAssignment("code-823", name: "name-478")
        try item.moveTo(ClinicalOps.OrderSetAssignmentStatus.active)
        #expect(item.status == ClinicalOps.OrderSetAssignmentStatus.active)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = ClinicalOps.newOrderSetAssignment("code-823", name: "name-478")
        item.status = ClinicalOps.OrderSetAssignmentStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.OrderSetAssignmentStatus.draft) }
    }
}
