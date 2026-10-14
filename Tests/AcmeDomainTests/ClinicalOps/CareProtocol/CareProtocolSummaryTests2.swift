@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsCareProtocolSummaryTests {
    @Test func startsInNew() throws {
        let item = ClinicalOps.newCareProtocolSummary("code-276", name: "name-372")
        #expect(item.status == ClinicalOps.CareProtocolSummaryStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToFailed() throws {
        let item = ClinicalOps.newCareProtocolSummary("code-276", name: "name-372")
        try item.moveTo(ClinicalOps.CareProtocolSummaryStatus.failed)
        #expect(item.status == ClinicalOps.CareProtocolSummaryStatus.failed)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = ClinicalOps.newCareProtocolSummary("code-276", name: "name-372")
        item.status = ClinicalOps.CareProtocolSummaryStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.CareProtocolSummaryStatus.new) }
    }
}
