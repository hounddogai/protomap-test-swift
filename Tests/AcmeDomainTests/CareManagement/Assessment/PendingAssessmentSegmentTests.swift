@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementPendingAssessmentSegmentTests {
    @Test func startsInProposed() throws {
        let item = CareManagement.newPendingAssessmentSegment("code-160", name: "name-320")
        #expect(item.status == CareManagement.PendingAssessmentSegmentStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToApproved() throws {
        let item = CareManagement.newPendingAssessmentSegment("code-160", name: "name-320")
        try item.moveTo(CareManagement.PendingAssessmentSegmentStatus.approved)
        #expect(item.status == CareManagement.PendingAssessmentSegmentStatus.approved)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = CareManagement.newPendingAssessmentSegment("code-160", name: "name-320")
        item.status = CareManagement.PendingAssessmentSegmentStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.PendingAssessmentSegmentStatus.proposed) }
    }
}
