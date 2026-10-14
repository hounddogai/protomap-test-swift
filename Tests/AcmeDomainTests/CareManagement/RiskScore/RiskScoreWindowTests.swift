@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementRiskScoreWindowTests {
    @Test func startsInOpen() throws {
        let item = CareManagement.newRiskScoreWindow("code-516", title: "title-105")
        #expect(item.status == CareManagement.RiskScoreWindowStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToInReview() throws {
        let item = CareManagement.newRiskScoreWindow("code-516", title: "title-105")
        try item.moveTo(CareManagement.RiskScoreWindowStatus.inReview)
        #expect(item.status == CareManagement.RiskScoreWindowStatus.inReview)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = CareManagement.newRiskScoreWindow("code-516", title: "title-105")
        item.status = CareManagement.RiskScoreWindowStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.RiskScoreWindowStatus.`open`) }
    }
}
