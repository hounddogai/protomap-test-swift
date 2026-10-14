@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementScheduledRiskScoreRecordTests {
    @Test func startsInOpen() throws {
        let item = CareManagement.newScheduledRiskScoreRecord("code-12", label: "label-545")
        #expect(item.status == CareManagement.ScheduledRiskScoreRecordStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToReopened() throws {
        let item = CareManagement.newScheduledRiskScoreRecord("code-12", label: "label-545")
        try item.moveTo(CareManagement.ScheduledRiskScoreRecordStatus.reopened)
        #expect(item.status == CareManagement.ScheduledRiskScoreRecordStatus.reopened)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = CareManagement.newScheduledRiskScoreRecord("code-12", label: "label-545")
        item.status = CareManagement.ScheduledRiskScoreRecordStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.ScheduledRiskScoreRecordStatus.`open`) }
    }
}
