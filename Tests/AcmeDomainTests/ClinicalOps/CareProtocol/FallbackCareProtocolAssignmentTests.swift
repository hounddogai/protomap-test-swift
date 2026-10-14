@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsFallbackCareProtocolAssignmentTests {
    @Test func startsInPlanned() throws {
        let item = ClinicalOps.newFallbackCareProtocolAssignment("code-752", label: "label-614")
        #expect(item.status == ClinicalOps.FallbackCareProtocolAssignmentStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToScheduled() throws {
        let item = ClinicalOps.newFallbackCareProtocolAssignment("code-752", label: "label-614")
        try item.moveTo(ClinicalOps.FallbackCareProtocolAssignmentStatus.scheduled)
        #expect(item.status == ClinicalOps.FallbackCareProtocolAssignmentStatus.scheduled)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = ClinicalOps.newFallbackCareProtocolAssignment("code-752", label: "label-614")
        item.status = ClinicalOps.FallbackCareProtocolAssignmentStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.FallbackCareProtocolAssignmentStatus.planned) }
    }
}
