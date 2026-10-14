@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsGlobalAlertSummaryTests {
    @Test func startsInNew() throws {
        let item = ClinicalOps.newGlobalAlertSummary("code-930", name: "name-550")
        #expect(item.status == ClinicalOps.GlobalAlertSummaryStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToRunning() throws {
        let item = ClinicalOps.newGlobalAlertSummary("code-930", name: "name-550")
        try item.moveTo(ClinicalOps.GlobalAlertSummaryStatus.running)
        #expect(item.status == ClinicalOps.GlobalAlertSummaryStatus.running)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = ClinicalOps.newGlobalAlertSummary("code-930", name: "name-550")
        item.status = ClinicalOps.GlobalAlertSummaryStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.GlobalAlertSummaryStatus.new) }
    }
}
