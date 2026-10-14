@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsAlertScoreTests {
    @Test func startsInOpen() throws {
        let item = ClinicalOps.newAlertScore("code-645", title: "title-988")
        #expect(item.status == ClinicalOps.AlertScoreStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToReopened() throws {
        let item = ClinicalOps.newAlertScore("code-645", title: "title-988")
        try item.moveTo(ClinicalOps.AlertScoreStatus.reopened)
        #expect(item.status == ClinicalOps.AlertScoreStatus.reopened)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = ClinicalOps.newAlertScore("code-645", title: "title-988")
        item.status = ClinicalOps.AlertScoreStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.AlertScoreStatus.`open`) }
    }
}
