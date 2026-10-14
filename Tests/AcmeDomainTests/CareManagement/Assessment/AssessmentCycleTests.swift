@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementAssessmentCycleTests {
    @Test func startsInCreated() throws {
        let item = CareManagement.newAssessmentCycle("code-686", title: "title-645")
        #expect(item.status == CareManagement.AssessmentCycleStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToValidated() throws {
        let item = CareManagement.newAssessmentCycle("code-686", title: "title-645")
        try item.moveTo(CareManagement.AssessmentCycleStatus.validated)
        #expect(item.status == CareManagement.AssessmentCycleStatus.validated)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = CareManagement.newAssessmentCycle("code-686", title: "title-645")
        item.status = CareManagement.AssessmentCycleStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.AssessmentCycleStatus.created) }
    }
}
