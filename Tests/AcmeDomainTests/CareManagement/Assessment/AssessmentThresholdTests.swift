@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementAssessmentThresholdTests {
    @Test func startsInPlanned() throws {
        let item = CareManagement.newAssessmentThreshold("code-320", label: "label-899")
        #expect(item.status == CareManagement.AssessmentThresholdStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToCompleted() throws {
        let item = CareManagement.newAssessmentThreshold("code-320", label: "label-899")
        try item.moveTo(CareManagement.AssessmentThresholdStatus.completed)
        #expect(item.status == CareManagement.AssessmentThresholdStatus.completed)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = CareManagement.newAssessmentThreshold("code-320", label: "label-899")
        item.status = CareManagement.AssessmentThresholdStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.AssessmentThresholdStatus.planned) }
    }
}
