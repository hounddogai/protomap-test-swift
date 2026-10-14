@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsFallbackAlertAssignmentTests {
    @Test func startsInPlanned() throws {
        let item = ClinicalOps.newFallbackAlertAssignment("code-554", title: "title-254")
        #expect(item.status == ClinicalOps.FallbackAlertAssignmentStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToScheduled() throws {
        let item = ClinicalOps.newFallbackAlertAssignment("code-554", title: "title-254")
        try item.moveTo(ClinicalOps.FallbackAlertAssignmentStatus.scheduled)
        #expect(item.status == ClinicalOps.FallbackAlertAssignmentStatus.scheduled)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = ClinicalOps.newFallbackAlertAssignment("code-554", title: "title-254")
        item.status = ClinicalOps.FallbackAlertAssignmentStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.FallbackAlertAssignmentStatus.planned) }
    }
}
