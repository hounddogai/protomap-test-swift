@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsAlertBaselineTests {
    @Test func startsInPlanned() throws {
        let item = ClinicalOps.newAlertBaseline("code-486", title: "title-753")
        #expect(item.status == ClinicalOps.AlertBaselineStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToCompleted() throws {
        let item = ClinicalOps.newAlertBaseline("code-486", title: "title-753")
        try item.moveTo(ClinicalOps.AlertBaselineStatus.completed)
        #expect(item.status == ClinicalOps.AlertBaselineStatus.completed)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = ClinicalOps.newAlertBaseline("code-486", title: "title-753")
        item.status = ClinicalOps.AlertBaselineStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.AlertBaselineStatus.planned) }
    }
}
