@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementGlobalIsolationSummaryTests {
    @Test func startsInDraft() throws {
        let item = BedManagement.newGlobalIsolationSummary("code-980", title: "title-483")
        #expect(item.status == BedManagement.GlobalIsolationSummaryStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToPending() throws {
        let item = BedManagement.newGlobalIsolationSummary("code-980", title: "title-483")
        try item.moveTo(BedManagement.GlobalIsolationSummaryStatus.pending)
        #expect(item.status == BedManagement.GlobalIsolationSummaryStatus.pending)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = BedManagement.newGlobalIsolationSummary("code-980", title: "title-483")
        item.status = BedManagement.GlobalIsolationSummaryStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.GlobalIsolationSummaryStatus.draft) }
    }
}
