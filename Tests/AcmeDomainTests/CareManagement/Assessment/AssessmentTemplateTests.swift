@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementAssessmentTemplateTests {
    @Test func startsInIdle() throws {
        let item = CareManagement.newAssessmentTemplate("code-438", name: "name-169")
        #expect(item.status == CareManagement.AssessmentTemplateStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToReady() throws {
        let item = CareManagement.newAssessmentTemplate("code-438", name: "name-169")
        try item.moveTo(CareManagement.AssessmentTemplateStatus.ready)
        #expect(item.status == CareManagement.AssessmentTemplateStatus.ready)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = CareManagement.newAssessmentTemplate("code-438", name: "name-169")
        item.status = CareManagement.AssessmentTemplateStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.AssessmentTemplateStatus.idle) }
    }
}
