@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementCappedRiskScoreWindowTests {
    @Test func startsInOpen() throws {
        let item = CareManagement.newCappedRiskScoreWindow("code-318", title: "title-111")
        #expect(item.status == CareManagement.CappedRiskScoreWindowStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToReopened() throws {
        let item = CareManagement.newCappedRiskScoreWindow("code-318", title: "title-111")
        try item.moveTo(CareManagement.CappedRiskScoreWindowStatus.reopened)
        #expect(item.status == CareManagement.CappedRiskScoreWindowStatus.reopened)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = CareManagement.newCappedRiskScoreWindow("code-318", title: "title-111")
        item.status = CareManagement.CappedRiskScoreWindowStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.CappedRiskScoreWindowStatus.`open`) }
    }
}
