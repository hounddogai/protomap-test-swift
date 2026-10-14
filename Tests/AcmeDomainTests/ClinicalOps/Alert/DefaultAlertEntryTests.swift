@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsDefaultAlertEntryTests {
    @Test func startsInPlanned() throws {
        let item = ClinicalOps.newDefaultAlertEntry("code-913", title: "title-387")
        #expect(item.status == ClinicalOps.DefaultAlertEntryStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToInProgress() throws {
        let item = ClinicalOps.newDefaultAlertEntry("code-913", title: "title-387")
        try item.moveTo(ClinicalOps.DefaultAlertEntryStatus.inProgress)
        #expect(item.status == ClinicalOps.DefaultAlertEntryStatus.inProgress)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = ClinicalOps.newDefaultAlertEntry("code-913", title: "title-387")
        item.status = ClinicalOps.DefaultAlertEntryStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.DefaultAlertEntryStatus.planned) }
    }
}
