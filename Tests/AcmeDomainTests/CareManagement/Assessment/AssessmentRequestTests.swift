@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementAssessmentRequestTests {
    @Test func startsInIdle() throws {
        let item = CareManagement.newAssessmentRequest("code-595", title: "title-42")
        #expect(item.status == CareManagement.AssessmentRequestStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToWarming() throws {
        let item = CareManagement.newAssessmentRequest("code-595", title: "title-42")
        try item.moveTo(CareManagement.AssessmentRequestStatus.warming)
        #expect(item.status == CareManagement.AssessmentRequestStatus.warming)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = CareManagement.newAssessmentRequest("code-595", title: "title-42")
        item.status = CareManagement.AssessmentRequestStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.AssessmentRequestStatus.idle) }
    }
}
