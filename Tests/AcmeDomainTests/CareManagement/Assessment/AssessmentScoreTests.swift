@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementAssessmentScoreTests {
    @Test func startsInProposed() throws {
        let item = CareManagement.newAssessmentScore("code-590", title: "title-597")
        #expect(item.status == CareManagement.AssessmentScoreStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToRejected() throws {
        let item = CareManagement.newAssessmentScore("code-590", title: "title-597")
        try item.moveTo(CareManagement.AssessmentScoreStatus.rejected)
        #expect(item.status == CareManagement.AssessmentScoreStatus.rejected)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = CareManagement.newAssessmentScore("code-590", title: "title-597")
        item.status = CareManagement.AssessmentScoreStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.AssessmentScoreStatus.proposed) }
    }
}
