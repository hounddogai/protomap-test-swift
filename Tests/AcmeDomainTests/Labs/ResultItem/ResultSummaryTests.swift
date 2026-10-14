@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsResultSummaryTests {
    @Test func startsInDraft() throws {
        let item = Labs.newResultSummary("code-534", label: "label-867")
        #expect(item.status == Labs.ResultSummaryStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToSuspended() throws {
        let item = Labs.newResultSummary("code-534", label: "label-867")
        try item.moveTo(Labs.ResultSummaryStatus.suspended)
        #expect(item.status == Labs.ResultSummaryStatus.suspended)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Labs.newResultSummary("code-534", label: "label-867")
        item.status = Labs.ResultSummaryStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Labs.ResultSummaryStatus.draft) }
    }
}
