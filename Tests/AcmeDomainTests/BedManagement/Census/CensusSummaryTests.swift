@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementCensusSummaryTests {
    @Test func startsInIdle() throws {
        let item = BedManagement.newCensusSummary("code-939", label: "label-21")
        #expect(item.status == BedManagement.CensusSummaryStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToStopped() throws {
        let item = BedManagement.newCensusSummary("code-939", label: "label-21")
        try item.moveTo(BedManagement.CensusSummaryStatus.stopped)
        #expect(item.status == BedManagement.CensusSummaryStatus.stopped)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = BedManagement.newCensusSummary("code-939", label: "label-21")
        item.status = BedManagement.CensusSummaryStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.CensusSummaryStatus.idle) }
    }
}
