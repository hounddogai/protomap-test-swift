@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementDefaultCleaningSummaryTests {
    @Test func startsInPlanned() throws {
        let item = BedManagement.newDefaultCleaningSummary("code-138", label: "label-978")
        #expect(item.status == BedManagement.DefaultCleaningSummaryStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToScheduled() throws {
        let item = BedManagement.newDefaultCleaningSummary("code-138", label: "label-978")
        try item.moveTo(BedManagement.DefaultCleaningSummaryStatus.scheduled)
        #expect(item.status == BedManagement.DefaultCleaningSummaryStatus.scheduled)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = BedManagement.newDefaultCleaningSummary("code-138", label: "label-978")
        item.status = BedManagement.DefaultCleaningSummaryStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.DefaultCleaningSummaryStatus.planned) }
    }
}
