@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementAssessmentSummaryTests {
    @Test func startsInRequested() throws {
        let item = CareManagement.newAssessmentSummary("code-34", label: "label-574")
        #expect(item.status == CareManagement.AssessmentSummaryStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToGranted() throws {
        let item = CareManagement.newAssessmentSummary("code-34", label: "label-574")
        try item.moveTo(CareManagement.AssessmentSummaryStatus.granted)
        #expect(item.status == CareManagement.AssessmentSummaryStatus.granted)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = CareManagement.newAssessmentSummary("code-34", label: "label-574")
        item.status = CareManagement.AssessmentSummaryStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.AssessmentSummaryStatus.requested) }
    }
}
