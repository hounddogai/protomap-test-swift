@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementRegionalAssessmentScoreTests {
    @Test func startsInOpen() throws {
        let item = CareManagement.newRegionalAssessmentScore("code-578", name: "name-939")
        #expect(item.status == CareManagement.RegionalAssessmentScoreStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToInReview() throws {
        let item = CareManagement.newRegionalAssessmentScore("code-578", name: "name-939")
        try item.moveTo(CareManagement.RegionalAssessmentScoreStatus.inReview)
        #expect(item.status == CareManagement.RegionalAssessmentScoreStatus.inReview)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = CareManagement.newRegionalAssessmentScore("code-578", name: "name-939")
        item.status = CareManagement.RegionalAssessmentScoreStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.RegionalAssessmentScoreStatus.`open`) }
    }
}
