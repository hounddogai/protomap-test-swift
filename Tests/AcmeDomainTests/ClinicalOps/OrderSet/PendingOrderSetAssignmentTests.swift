@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsPendingOrderSetAssignmentTests {
    @Test func startsInNew() throws {
        let item = ClinicalOps.newPendingOrderSetAssignment("code-144", name: "name-715")
        #expect(item.status == ClinicalOps.PendingOrderSetAssignmentStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToDone() throws {
        let item = ClinicalOps.newPendingOrderSetAssignment("code-144", name: "name-715")
        try item.moveTo(ClinicalOps.PendingOrderSetAssignmentStatus.done)
        #expect(item.status == ClinicalOps.PendingOrderSetAssignmentStatus.done)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = ClinicalOps.newPendingOrderSetAssignment("code-144", name: "name-715")
        item.status = ClinicalOps.PendingOrderSetAssignmentStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.PendingOrderSetAssignmentStatus.new) }
    }
}
