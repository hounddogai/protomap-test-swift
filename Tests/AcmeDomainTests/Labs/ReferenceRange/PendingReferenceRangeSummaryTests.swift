@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsPendingReferenceRangeSummaryTests {
    @Test func startsInNew() throws {
        let item = Labs.newPendingReferenceRangeSummary("code-140", title: "title-438")
        #expect(item.status == Labs.PendingReferenceRangeSummaryStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToRunning() throws {
        let item = Labs.newPendingReferenceRangeSummary("code-140", title: "title-438")
        try item.moveTo(Labs.PendingReferenceRangeSummaryStatus.running)
        #expect(item.status == Labs.PendingReferenceRangeSummaryStatus.running)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Labs.newPendingReferenceRangeSummary("code-140", title: "title-438")
        item.status = Labs.PendingReferenceRangeSummaryStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Labs.PendingReferenceRangeSummaryStatus.new) }
    }
}
