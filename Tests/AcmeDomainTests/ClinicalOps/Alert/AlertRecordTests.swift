@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsAlertRecordTests {
    @Test func startsInProposed() throws {
        let item = ClinicalOps.newAlertRecord("code-412", label: "label-150")
        #expect(item.status == ClinicalOps.AlertRecordStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToRejected() throws {
        let item = ClinicalOps.newAlertRecord("code-412", label: "label-150")
        try item.moveTo(ClinicalOps.AlertRecordStatus.rejected)
        #expect(item.status == ClinicalOps.AlertRecordStatus.rejected)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = ClinicalOps.newAlertRecord("code-412", label: "label-150")
        item.status = ClinicalOps.AlertRecordStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.AlertRecordStatus.proposed) }
    }
}
