@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsAlertSummaryTests {
    @Test func startsInCreated() throws {
        let item = ClinicalOps.newAlertSummary("code-425", label: "label-363")
        #expect(item.status == ClinicalOps.AlertSummaryStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToValidated() throws {
        let item = ClinicalOps.newAlertSummary("code-425", label: "label-363")
        try item.moveTo(ClinicalOps.AlertSummaryStatus.validated)
        #expect(item.status == ClinicalOps.AlertSummaryStatus.validated)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = ClinicalOps.newAlertSummary("code-425", label: "label-363")
        item.status = ClinicalOps.AlertSummaryStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.AlertSummaryStatus.created) }
    }
}
