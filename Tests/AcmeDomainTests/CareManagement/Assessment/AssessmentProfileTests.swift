@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementAssessmentProfileTests {
    @Test func startsInCreated() throws {
        let item = CareManagement.newAssessmentProfile("code-184", name: "name-734")
        #expect(item.status == CareManagement.AssessmentProfileStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToValidated() throws {
        let item = CareManagement.newAssessmentProfile("code-184", name: "name-734")
        try item.moveTo(CareManagement.AssessmentProfileStatus.validated)
        #expect(item.status == CareManagement.AssessmentProfileStatus.validated)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = CareManagement.newAssessmentProfile("code-184", name: "name-734")
        item.status = CareManagement.AssessmentProfileStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.AssessmentProfileStatus.created) }
    }
}
