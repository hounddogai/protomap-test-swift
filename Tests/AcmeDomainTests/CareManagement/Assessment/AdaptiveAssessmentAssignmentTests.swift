@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementAdaptiveAssessmentAssignmentTests {
    @Test func startsInIdle() throws {
        let item = CareManagement.newAdaptiveAssessmentAssignment("code-586", title: "title-500")
        #expect(item.status == CareManagement.AdaptiveAssessmentAssignmentStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToDraining() throws {
        let item = CareManagement.newAdaptiveAssessmentAssignment("code-586", title: "title-500")
        try item.moveTo(CareManagement.AdaptiveAssessmentAssignmentStatus.draining)
        #expect(item.status == CareManagement.AdaptiveAssessmentAssignmentStatus.draining)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = CareManagement.newAdaptiveAssessmentAssignment("code-586", title: "title-500")
        item.status = CareManagement.AdaptiveAssessmentAssignmentStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.AdaptiveAssessmentAssignmentStatus.idle) }
    }
}
