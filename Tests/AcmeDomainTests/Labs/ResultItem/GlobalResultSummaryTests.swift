@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsGlobalResultSummaryTests {
    @Test func startsInCreated() throws {
        let item = Labs.newGlobalResultSummary("code-368", label: "label-396")
        #expect(item.status == Labs.GlobalResultSummaryStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToValidated() throws {
        let item = Labs.newGlobalResultSummary("code-368", label: "label-396")
        try item.moveTo(Labs.GlobalResultSummaryStatus.validated)
        #expect(item.status == Labs.GlobalResultSummaryStatus.validated)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = Labs.newGlobalResultSummary("code-368", label: "label-396")
        item.status = Labs.GlobalResultSummaryStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(Labs.GlobalResultSummaryStatus.created) }
    }
}
