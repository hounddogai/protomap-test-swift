@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsTieredTaskSummaryTests {
    @Test func startsInPlanned() throws {
        let item = ClinicalOps.newTieredTaskSummary("code-859", title: "title-504")
        #expect(item.status == ClinicalOps.TieredTaskSummaryStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToScheduled() throws {
        let item = ClinicalOps.newTieredTaskSummary("code-859", title: "title-504")
        try item.moveTo(ClinicalOps.TieredTaskSummaryStatus.scheduled)
        #expect(item.status == ClinicalOps.TieredTaskSummaryStatus.scheduled)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = ClinicalOps.newTieredTaskSummary("code-859", title: "title-504")
        item.status = ClinicalOps.TieredTaskSummaryStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.TieredTaskSummaryStatus.planned) }
    }
}
