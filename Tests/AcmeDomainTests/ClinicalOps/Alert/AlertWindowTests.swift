@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsAlertWindowTests {
    @Test func startsInPlanned() throws {
        let item = ClinicalOps.newAlertWindow("code-476", title: "title-819")
        #expect(item.status == ClinicalOps.AlertWindowStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToScheduled() throws {
        let item = ClinicalOps.newAlertWindow("code-476", title: "title-819")
        try item.moveTo(ClinicalOps.AlertWindowStatus.scheduled)
        #expect(item.status == ClinicalOps.AlertWindowStatus.scheduled)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = ClinicalOps.newAlertWindow("code-476", title: "title-819")
        item.status = ClinicalOps.AlertWindowStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.AlertWindowStatus.planned) }
    }
}
