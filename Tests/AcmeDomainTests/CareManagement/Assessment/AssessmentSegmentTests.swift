@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementAssessmentSegmentTests {
    @Test func startsInDraft() throws {
        let item = CareManagement.newAssessmentSegment("code-58", label: "label-926")
        #expect(item.status == CareManagement.AssessmentSegmentStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToPending() throws {
        let item = CareManagement.newAssessmentSegment("code-58", label: "label-926")
        try item.moveTo(CareManagement.AssessmentSegmentStatus.pending)
        #expect(item.status == CareManagement.AssessmentSegmentStatus.pending)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = CareManagement.newAssessmentSegment("code-58", label: "label-926")
        item.status = CareManagement.AssessmentSegmentStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.AssessmentSegmentStatus.draft) }
    }
}
