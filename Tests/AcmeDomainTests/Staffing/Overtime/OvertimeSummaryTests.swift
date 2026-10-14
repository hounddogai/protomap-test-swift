@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingOvertimeSummaryTests {
    @Test func startsInNew() throws {
        let item = Staffing.newOvertimeSummary("code-148", title: "title-166")
        #expect(item.status == Staffing.OvertimeSummaryStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToFailed() throws {
        let item = Staffing.newOvertimeSummary("code-148", title: "title-166")
        try item.moveTo(Staffing.OvertimeSummaryStatus.failed)
        #expect(item.status == Staffing.OvertimeSummaryStatus.failed)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Staffing.newOvertimeSummary("code-148", title: "title-166")
        item.status = Staffing.OvertimeSummaryStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.OvertimeSummaryStatus.new) }
    }
}
