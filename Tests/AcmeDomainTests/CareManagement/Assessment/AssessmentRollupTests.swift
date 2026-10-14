@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementAssessmentRollupTests {
    @Test func startsInOpen() throws {
        let item = CareManagement.newAssessmentRollup("code-868", label: "label-517")
        #expect(item.status == CareManagement.AssessmentRollupStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToReopened() throws {
        let item = CareManagement.newAssessmentRollup("code-868", label: "label-517")
        try item.moveTo(CareManagement.AssessmentRollupStatus.reopened)
        #expect(item.status == CareManagement.AssessmentRollupStatus.reopened)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = CareManagement.newAssessmentRollup("code-868", label: "label-517")
        item.status = CareManagement.AssessmentRollupStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.AssessmentRollupStatus.`open`) }
    }
}
