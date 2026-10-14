@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingRegionalFloatPoolSummaryTests {
    @Test func startsInDraft() throws {
        let item = Staffing.newRegionalFloatPoolSummary("code-178", title: "title-521")
        #expect(item.status == Staffing.RegionalFloatPoolSummaryStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToActive() throws {
        let item = Staffing.newRegionalFloatPoolSummary("code-178", title: "title-521")
        try item.moveTo(Staffing.RegionalFloatPoolSummaryStatus.active)
        #expect(item.status == Staffing.RegionalFloatPoolSummaryStatus.active)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Staffing.newRegionalFloatPoolSummary("code-178", title: "title-521")
        item.status = Staffing.RegionalFloatPoolSummaryStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.RegionalFloatPoolSummaryStatus.draft) }
    }
}
