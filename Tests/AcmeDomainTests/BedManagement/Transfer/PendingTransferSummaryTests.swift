@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementPendingTransferSummaryTests {
    @Test func startsInNew() throws {
        let item = BedManagement.newPendingTransferSummary("code-410", label: "label-571")
        #expect(item.status == BedManagement.PendingTransferSummaryStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToRunning() throws {
        let item = BedManagement.newPendingTransferSummary("code-410", label: "label-571")
        try item.moveTo(BedManagement.PendingTransferSummaryStatus.running)
        #expect(item.status == BedManagement.PendingTransferSummaryStatus.running)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = BedManagement.newPendingTransferSummary("code-410", label: "label-571")
        item.status = BedManagement.PendingTransferSummaryStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.PendingTransferSummaryStatus.new) }
    }
}
