@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsPrimaryResultSummaryTests {
    @Test func startsInDraft() throws {
        let item = Labs.newPrimaryResultSummary("code-243", name: "name-856")
        #expect(item.status == Labs.PrimaryResultSummaryStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToPending() throws {
        let item = Labs.newPrimaryResultSummary("code-243", name: "name-856")
        try item.moveTo(Labs.PrimaryResultSummaryStatus.pending)
        #expect(item.status == Labs.PrimaryResultSummaryStatus.pending)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Labs.newPrimaryResultSummary("code-243", name: "name-856")
        item.status = Labs.PrimaryResultSummaryStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Labs.PrimaryResultSummaryStatus.draft) }
    }
}
