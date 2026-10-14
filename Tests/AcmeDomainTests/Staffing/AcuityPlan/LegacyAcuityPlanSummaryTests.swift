@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingLegacyAcuityPlanSummaryTests {
    @Test func startsInDraft() throws {
        let item = Staffing.newLegacyAcuityPlanSummary("code-611", title: "title-302")
        #expect(item.status == Staffing.LegacyAcuityPlanSummaryStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToActive() throws {
        let item = Staffing.newLegacyAcuityPlanSummary("code-611", title: "title-302")
        try item.moveTo(Staffing.LegacyAcuityPlanSummaryStatus.active)
        #expect(item.status == Staffing.LegacyAcuityPlanSummaryStatus.active)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Staffing.newLegacyAcuityPlanSummary("code-611", title: "title-302")
        item.status = Staffing.LegacyAcuityPlanSummaryStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.LegacyAcuityPlanSummaryStatus.draft) }
    }
}
