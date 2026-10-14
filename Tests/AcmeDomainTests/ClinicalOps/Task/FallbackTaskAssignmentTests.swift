@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsFallbackTaskAssignmentTests {
    @Test func startsInIdle() throws {
        let item = ClinicalOps.newFallbackTaskAssignment("code-880", label: "label-774")
        #expect(item.status == ClinicalOps.FallbackTaskAssignmentStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToWarming() throws {
        let item = ClinicalOps.newFallbackTaskAssignment("code-880", label: "label-774")
        try item.moveTo(ClinicalOps.FallbackTaskAssignmentStatus.warming)
        #expect(item.status == ClinicalOps.FallbackTaskAssignmentStatus.warming)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = ClinicalOps.newFallbackTaskAssignment("code-880", label: "label-774")
        item.status = ClinicalOps.FallbackTaskAssignmentStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.FallbackTaskAssignmentStatus.idle) }
    }
}
