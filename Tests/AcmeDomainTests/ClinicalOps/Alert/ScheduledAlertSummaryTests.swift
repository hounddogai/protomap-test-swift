@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsScheduledAlertSummaryTests {
    @Test func startsInCreated() throws {
        let item = ClinicalOps.newScheduledAlertSummary("code-66", label: "label-620")
        #expect(item.status == ClinicalOps.ScheduledAlertSummaryStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToValidated() throws {
        let item = ClinicalOps.newScheduledAlertSummary("code-66", label: "label-620")
        try item.moveTo(ClinicalOps.ScheduledAlertSummaryStatus.validated)
        #expect(item.status == ClinicalOps.ScheduledAlertSummaryStatus.validated)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = ClinicalOps.newScheduledAlertSummary("code-66", label: "label-620")
        item.status = ClinicalOps.ScheduledAlertSummaryStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.ScheduledAlertSummaryStatus.created) }
    }
}
