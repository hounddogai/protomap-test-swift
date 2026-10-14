@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsFallbackOrderSetSummaryTests {
    @Test func startsInCreated() throws {
        let item = ClinicalOps.newFallbackOrderSetSummary("code-231", title: "title-184")
        #expect(item.status == ClinicalOps.FallbackOrderSetSummaryStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToPublished() throws {
        let item = ClinicalOps.newFallbackOrderSetSummary("code-231", title: "title-184")
        try item.moveTo(ClinicalOps.FallbackOrderSetSummaryStatus.published)
        #expect(item.status == ClinicalOps.FallbackOrderSetSummaryStatus.published)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = ClinicalOps.newFallbackOrderSetSummary("code-231", title: "title-184")
        item.status = ClinicalOps.FallbackOrderSetSummaryStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.FallbackOrderSetSummaryStatus.created) }
    }
}
