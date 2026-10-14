@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyGlobalRecallSummaryTests {
    @Test func startsInNew() throws {
        let item = Pharmacy.newGlobalRecallSummary("code-290", title: "title-746")
        #expect(item.status == Pharmacy.GlobalRecallSummaryStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToQueued() throws {
        let item = Pharmacy.newGlobalRecallSummary("code-290", title: "title-746")
        try item.moveTo(Pharmacy.GlobalRecallSummaryStatus.queued)
        #expect(item.status == Pharmacy.GlobalRecallSummaryStatus.queued)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Pharmacy.newGlobalRecallSummary("code-290", title: "title-746")
        item.status = Pharmacy.GlobalRecallSummaryStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.GlobalRecallSummaryStatus.new) }
    }
}
