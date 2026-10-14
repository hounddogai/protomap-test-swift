@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsAdaptiveAlertSummaryTests {
    @Test func startsInDraft() throws {
        let item = ClinicalOps.newAdaptiveAlertSummary("code-748", title: "title-72")
        #expect(item.status == ClinicalOps.AdaptiveAlertSummaryStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToSuspended() throws {
        let item = ClinicalOps.newAdaptiveAlertSummary("code-748", title: "title-72")
        try item.moveTo(ClinicalOps.AdaptiveAlertSummaryStatus.suspended)
        #expect(item.status == ClinicalOps.AdaptiveAlertSummaryStatus.suspended)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = ClinicalOps.newAdaptiveAlertSummary("code-748", title: "title-72")
        item.status = ClinicalOps.AdaptiveAlertSummaryStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.AdaptiveAlertSummaryStatus.draft) }
    }
}
