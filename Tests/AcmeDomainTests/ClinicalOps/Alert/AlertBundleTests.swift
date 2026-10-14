@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsAlertBundleTests {
    @Test func startsInProposed() throws {
        let item = ClinicalOps.newAlertBundle("code-806", label: "label-319")
        #expect(item.status == ClinicalOps.AlertBundleStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToRejected() throws {
        let item = ClinicalOps.newAlertBundle("code-806", label: "label-319")
        try item.moveTo(ClinicalOps.AlertBundleStatus.rejected)
        #expect(item.status == ClinicalOps.AlertBundleStatus.rejected)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = ClinicalOps.newAlertBundle("code-806", label: "label-319")
        item.status = ClinicalOps.AlertBundleStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.AlertBundleStatus.proposed) }
    }
}
