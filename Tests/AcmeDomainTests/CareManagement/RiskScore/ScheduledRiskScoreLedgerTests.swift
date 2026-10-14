@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementScheduledRiskScoreLedgerTests {
    @Test func startsInCreated() throws {
        let item = CareManagement.newScheduledRiskScoreLedger("code-57", title: "title-160")
        #expect(item.status == CareManagement.ScheduledRiskScoreLedgerStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToPublished() throws {
        let item = CareManagement.newScheduledRiskScoreLedger("code-57", title: "title-160")
        try item.moveTo(CareManagement.ScheduledRiskScoreLedgerStatus.published)
        #expect(item.status == CareManagement.ScheduledRiskScoreLedgerStatus.published)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = CareManagement.newScheduledRiskScoreLedger("code-57", title: "title-160")
        item.status = CareManagement.ScheduledRiskScoreLedgerStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.ScheduledRiskScoreLedgerStatus.created) }
    }
}
