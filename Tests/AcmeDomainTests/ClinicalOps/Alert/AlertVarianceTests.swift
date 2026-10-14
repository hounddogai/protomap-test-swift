@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsAlertVarianceTests {
    @Test func startsInProposed() throws {
        let item = ClinicalOps.newAlertVariance("code-559", label: "label-591")
        #expect(item.status == ClinicalOps.AlertVarianceStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToRejected() throws {
        let item = ClinicalOps.newAlertVariance("code-559", label: "label-591")
        try item.moveTo(ClinicalOps.AlertVarianceStatus.rejected)
        #expect(item.status == ClinicalOps.AlertVarianceStatus.rejected)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = ClinicalOps.newAlertVariance("code-559", label: "label-591")
        item.status = ClinicalOps.AlertVarianceStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.AlertVarianceStatus.proposed) }
    }
}
