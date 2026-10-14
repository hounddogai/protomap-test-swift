@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsAlertSegmentTests {
    @Test func startsInPlanned() throws {
        let item = ClinicalOps.newAlertSegment("code-894", label: "label-249")
        #expect(item.status == ClinicalOps.AlertSegmentStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToScheduled() throws {
        let item = ClinicalOps.newAlertSegment("code-894", label: "label-249")
        try item.moveTo(ClinicalOps.AlertSegmentStatus.scheduled)
        #expect(item.status == ClinicalOps.AlertSegmentStatus.scheduled)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = ClinicalOps.newAlertSegment("code-894", label: "label-249")
        item.status = ClinicalOps.AlertSegmentStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.AlertSegmentStatus.planned) }
    }
}
