@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsAlertCycleTests {
    @Test func startsInCreated() throws {
        let item = ClinicalOps.newAlertCycle("code-521", label: "label-845")
        #expect(item.status == ClinicalOps.AlertCycleStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToRetired() throws {
        let item = ClinicalOps.newAlertCycle("code-521", label: "label-845")
        try item.moveTo(ClinicalOps.AlertCycleStatus.retired)
        #expect(item.status == ClinicalOps.AlertCycleStatus.retired)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = ClinicalOps.newAlertCycle("code-521", label: "label-845")
        item.status = ClinicalOps.AlertCycleStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.AlertCycleStatus.created) }
    }
}
