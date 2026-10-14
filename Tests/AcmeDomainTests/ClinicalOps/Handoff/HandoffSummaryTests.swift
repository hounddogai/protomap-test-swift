@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsHandoffSummaryTests {
    @Test func startsInNew() throws {
        let item = ClinicalOps.newHandoffSummary("code-884", title: "title-153")
        #expect(item.status == ClinicalOps.HandoffSummaryStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToQueued() throws {
        let item = ClinicalOps.newHandoffSummary("code-884", title: "title-153")
        try item.moveTo(ClinicalOps.HandoffSummaryStatus.queued)
        #expect(item.status == ClinicalOps.HandoffSummaryStatus.queued)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = ClinicalOps.newHandoffSummary("code-884", title: "title-153")
        item.status = ClinicalOps.HandoffSummaryStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.HandoffSummaryStatus.new) }
    }
}
