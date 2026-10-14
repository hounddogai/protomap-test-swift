@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsDefaultCareProtocolSummaryTests {
    @Test func startsInPlanned() throws {
        let item = ClinicalOps.newDefaultCareProtocolSummary("code-671", name: "name-184")
        #expect(item.status == ClinicalOps.DefaultCareProtocolSummaryStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToCancelled() throws {
        let item = ClinicalOps.newDefaultCareProtocolSummary("code-671", name: "name-184")
        try item.moveTo(ClinicalOps.DefaultCareProtocolSummaryStatus.cancelled)
        #expect(item.status == ClinicalOps.DefaultCareProtocolSummaryStatus.cancelled)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = ClinicalOps.newDefaultCareProtocolSummary("code-671", name: "name-184")
        item.status = ClinicalOps.DefaultCareProtocolSummaryStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.DefaultCareProtocolSummaryStatus.planned) }
    }
}
