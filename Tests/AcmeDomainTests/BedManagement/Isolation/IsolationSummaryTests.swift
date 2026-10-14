@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementIsolationSummaryTests {
    @Test func startsInIdle() throws {
        let item = BedManagement.newIsolationSummary("code-483", label: "label-634")
        #expect(item.status == BedManagement.IsolationSummaryStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToWarming() throws {
        let item = BedManagement.newIsolationSummary("code-483", label: "label-634")
        try item.moveTo(BedManagement.IsolationSummaryStatus.warming)
        #expect(item.status == BedManagement.IsolationSummaryStatus.warming)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = BedManagement.newIsolationSummary("code-483", label: "label-634")
        item.status = BedManagement.IsolationSummaryStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.IsolationSummaryStatus.idle) }
    }
}
