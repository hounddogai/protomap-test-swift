@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementAssessmentBaselineTests {
    @Test func startsInCreated() throws {
        let item = CareManagement.newAssessmentBaseline("code-82", name: "name-208")
        #expect(item.status == CareManagement.AssessmentBaselineStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToPublished() throws {
        let item = CareManagement.newAssessmentBaseline("code-82", name: "name-208")
        try item.moveTo(CareManagement.AssessmentBaselineStatus.published)
        #expect(item.status == CareManagement.AssessmentBaselineStatus.published)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = CareManagement.newAssessmentBaseline("code-82", name: "name-208")
        item.status = CareManagement.AssessmentBaselineStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.AssessmentBaselineStatus.created) }
    }
}
