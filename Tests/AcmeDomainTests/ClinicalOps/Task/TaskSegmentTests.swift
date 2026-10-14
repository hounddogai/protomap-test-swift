@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsTaskSegmentTests {
    @Test func startsInPlanned() throws {
        let item = ClinicalOps.newTaskSegment("code-356", name: "name-432")
        #expect(item.status == ClinicalOps.TaskSegmentStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToScheduled() throws {
        let item = ClinicalOps.newTaskSegment("code-356", name: "name-432")
        try item.moveTo(ClinicalOps.TaskSegmentStatus.scheduled)
        #expect(item.status == ClinicalOps.TaskSegmentStatus.scheduled)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = ClinicalOps.newTaskSegment("code-356", name: "name-432")
        item.status = ClinicalOps.TaskSegmentStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.TaskSegmentStatus.planned) }
    }
}
