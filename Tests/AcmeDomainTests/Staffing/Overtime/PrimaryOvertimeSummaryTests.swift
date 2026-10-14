@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingPrimaryOvertimeSummaryTests {
    @Test func startsInProposed() throws {
        let item = Staffing.newPrimaryOvertimeSummary("code-370", title: "title-225")
        #expect(item.status == Staffing.PrimaryOvertimeSummaryStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToApproved() throws {
        let item = Staffing.newPrimaryOvertimeSummary("code-370", title: "title-225")
        try item.moveTo(Staffing.PrimaryOvertimeSummaryStatus.approved)
        #expect(item.status == Staffing.PrimaryOvertimeSummaryStatus.approved)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Staffing.newPrimaryOvertimeSummary("code-370", title: "title-225")
        item.status = Staffing.PrimaryOvertimeSummaryStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.PrimaryOvertimeSummaryStatus.proposed) }
    }
}
