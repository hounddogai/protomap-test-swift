@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingSeasonalAcuityPlanSummaryTests {
    @Test func startsInNew() throws {
        let item = Staffing.newSeasonalAcuityPlanSummary("code-961", name: "name-924")
        #expect(item.status == Staffing.SeasonalAcuityPlanSummaryStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToDone() throws {
        let item = Staffing.newSeasonalAcuityPlanSummary("code-961", name: "name-924")
        try item.moveTo(Staffing.SeasonalAcuityPlanSummaryStatus.done)
        #expect(item.status == Staffing.SeasonalAcuityPlanSummaryStatus.done)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Staffing.newSeasonalAcuityPlanSummary("code-961", name: "name-924")
        item.status = Staffing.SeasonalAcuityPlanSummaryStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.SeasonalAcuityPlanSummaryStatus.new) }
    }
}
